%%%-------------------------------------------------------------------
%%% @copyright (C) 2011-2016, 2600Hz INC
%%% @doc
%%%
%%% Handle client requests for phone_number documents
%%%
%%% @end
%%% @contributors
%%%   Karl Anderson
%%%   Pierre Fenoll
%%%-------------------------------------------------------------------
-module(knm_other).
-behaviour(knm_gen_carrier).

-export([is_local/0]).
-export([find_numbers/3]).
-export([is_number_billable/1]).
-export([acquire_number/1]).
-export([disconnect_number/1]).
-export([should_lookup_cnam/0]).
-export([check_numbers/1]).

-include("knm.hrl").

-define(KNM_OTHER_CONFIG_CAT, <<?KNM_CONFIG_CAT/binary, ".other">>).

-ifdef(TEST).
-define(COUNTRY, ?KNM_DEFAULT_COUNTRY).
-else.
-define(COUNTRY
       ,kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"default_country">>, ?KNM_DEFAULT_COUNTRY)).
-endif.

-ifdef(TEST).
-define(PHONEBOOK_URL(Options)
       ,props:get_value('phonebook_url', Options)).
-else.
-define(PHONEBOOK_URL(_Options)
       ,kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"phonebook_url">>)).
-endif.


%%--------------------------------------------------------------------
%% @public
%% @doc
%% Is this carrier handling numbers local to the system?
%% Note: a non-local (foreign) carrier module makes HTTP requests.
%% @end
%%--------------------------------------------------------------------
-spec is_local() -> boolean().
is_local() -> 'false'.

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Query the local system for a quanity of available numbers
%% in a rate center
%% @end
%%--------------------------------------------------------------------
-spec find_numbers(ne_binary(), pos_integer(), knm_search:options()) ->
                          {'ok', list()} |
                          {'bulk', list()} |
                          {'error', any()}.
find_numbers(Prefix, Quantity, Options) ->
    case ?PHONEBOOK_URL(Options) of
        'undefined' -> {'error', 'not_available'};
        Url ->
            case props:is_defined('blocks', Options) of
                'false' -> get_numbers(Url, Prefix, Quantity, Options);
                'true' -> get_blocks(Url, Prefix, Quantity, Options)
            end
    end.

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Check with carrier if these numbers are registered with it.
%% @end
%%--------------------------------------------------------------------
-spec check_numbers(ne_binaries()) -> {'ok', kz_json:object()} |
                                      {'error', any()}.
check_numbers(Numbers) ->
    FormatedNumbers = [knm_converters:to_npan(Number) || Number <- Numbers],
    case kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"phonebook_url">>) of
        'undefined' -> {'error', 'not_available'};
        Url ->
            DefaultCountry = kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"default_country">>, ?KNM_DEFAULT_COUNTRY),
            ReqBody = kz_json:set_value(<<"data">>, FormatedNumbers, kz_json:new()),
            Uri = <<Url/binary,  "/numbers/", DefaultCountry/binary, "/status">>,
            lager:debug("making request to ~s with body ~p", [Uri, ReqBody]),
            case kz_http:post(binary:bin_to_list(Uri), [], kz_json:encode(ReqBody)) of
                {'ok', 200, _Headers, Body} ->
                    format_check_numbers(kz_json:decode(Body));
                {'ok', _Status, _Headers, Body} ->
                    lager:error("numbers check failed: ~p", [Body]),
                    {'error', Body};
                E ->
                    lager:error("numbers check failed: error ~p", [E]),
                    E
            end
    end.

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Query the local system for a quanity of available numbers
%% in a rate center
%% @end
%%--------------------------------------------------------------------
-spec is_number_billable(knm_phone_number:knm_phone_number()) -> boolean().
is_number_billable(_Number) -> 'true'.

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Acquire a given number from the carrier
%% @end
%%--------------------------------------------------------------------
-spec acquire_number(knm_number:knm_number()) -> knm_number:knm_number().
acquire_number(Number) ->
    Num = knm_phone_number:number(knm_number:phone_number(Number)),
    DefaultCountry = kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"default_country">>, ?KNM_DEFAULT_COUNTRY),
    case kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"phonebook_url">>) of
        'undefined' ->
            knm_errors:unspecified('missing_provider_url', Num);
        Url ->
            Hosts = case kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"endpoints">>) of
                        'undefined' -> [];
                        Endpoint when is_binary(Endpoint) ->
                            [Endpoint];
                        Endpoints -> Endpoints
                    end,

            ReqBody = kz_json:set_values([{[<<"data">>, <<"numbers">>], [Num]}
                                         ,{[<<"data">>, <<"gateways">>], Hosts}
                                         ]
                                        ,kz_json:new()
                                        ),

            Uri = <<Url/binary,  "/numbers/", DefaultCountry/binary, "/order">>,
            case kz_http:put(binary:bin_to_list(Uri), [], kz_json:encode(ReqBody)) of
                {'ok', 200, _Headers, Body} ->
                    format_acquire_resp(Number, kz_json:decode(Body));
                {'ok', _Status, _Headers, Body} ->
                    lager:error("number lookup failed to ~s with ~p: ~s"
                               ,[Uri, _Status, Body]),
                    knm_errors:by_carrier(?MODULE, 'lookup_failed', Num);
                {'error', Reason} ->
                    knm_errors:by_carrier(?MODULE, Reason, Num)
            end
    end.

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Release a number from the routing table
%% @end
%%--------------------------------------------------------------------
-spec disconnect_number(knm_number:knm_number()) -> knm_number:knm_number().
disconnect_number(Number) -> Number.

%%--------------------------------------------------------------------
%% @public
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec should_lookup_cnam() -> 'true'.
should_lookup_cnam() -> 'true'.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec format_check_numbers(kz_json:object()) ->
                                  {'ok', kz_json:object()} |
                                  {'error', 'resp_error'}.
format_check_numbers(Body) ->
    case kz_json:get_value(<<"status">>, Body) of
        <<"success">> ->
            format_check_numbers_success(Body);
        _Error ->
            lager:error("number check resp error: ~p", [_Error]),
            {'error', 'resp_error'}
    end.

-spec format_check_numbers_success(kz_json:object()) ->
                                          {'ok', kz_json:object()}.
format_check_numbers_success(Body) ->
    F = fun(NumberJObj, Acc) ->
                Number = kz_json:get_value(<<"number">>, NumberJObj),
                Status = kz_json:get_value(<<"status">>, NumberJObj),
                kz_json:set_value(Number, Status, Acc)
        end,
    JObj = lists:foldl(F
                      ,kz_json:new()
                      ,kz_json:get_value(<<"data">>, Body, [])
                      ),
    {'ok', JObj}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec get_numbers(ne_binary(), ne_binary(), ne_binary(), knm_search:options()) ->
                         {'ok', list()} |
                         {'error', 'not_available'}.
get_numbers(Url, Prefix, Quantity, Options) ->
    Offset = props:get_binary_value('offset', Options, <<"0">>),
    ReqBody = <<"?prefix=", Prefix/binary, "&limit=", (kz_util:to_binary(Quantity))/binary, "&offset=", Offset/binary>>,
    Uri = <<Url/binary, "/numbers/", (?COUNTRY)/binary, "/search", ReqBody/binary>>,
    Results = query_for_numbers(Uri),
    handle_number_query_results(Results, Options).

-spec query_for_numbers(ne_binary()) -> kz_http:http_ret().
-ifdef(TEST).
query_for_numbers(<<?NUMBER_PHONEBOOK_URL_L, _/binary>>) ->
    {'ok', 200, [], kz_json:encode(?NUMBERS_RESPONSE)}.
-else.
query_for_numbers(Uri) ->
    lager:debug("querying ~s for numbers", [Uri]),
    kz_http:get(binary:bin_to_list(Uri)).
-endif.

-spec handle_number_query_results(kz_http:http_ret(), knm_search:options()) ->
                                         {'ok', list()} |
                                         {'error', 'not_available'}.
handle_number_query_results({'error', _Reason}, _Options) ->
    lager:error("number query failed: ~p", [_Reason]),
    {'error', 'not_available'};
handle_number_query_results({'ok', 200, _Headers, Body}, Options) ->
    format_numbers_resp(kz_json:decode(Body), Options);
handle_number_query_results({'ok', _Status, _Headers, _Body}, _Options) ->
    lager:error("number query failed with ~p: ~s", [_Status, _Body]),
    {'error', 'not_available'}.

-spec format_numbers_resp(kz_json:object(), knm_search:options()) ->
                                 {'ok', list()} |
                                 {'error', 'not_available'}.
format_numbers_resp(JObj, Options) ->
    case kz_json:get_value(<<"status">>, JObj) of
        <<"success">> ->
            DataJObj = kz_json:get_value(<<"data">>, JObj),
            QID = knm_search:query_id(Options),
            Numbers = [format_found(QID, DID, CarrierData)
                       || {DID, CarrierData} <- kz_json:to_proplist(DataJObj)
                      ],
            {'ok', Numbers};
        _Error ->
            lager:error("block lookup resp error: ~p", [_Error]),
            {'error', 'not_available'}
    end.

format_found(QID, DID, CarrierData) ->
    {QID, {DID, ?MODULE, ?NUMBER_STATE_DISCOVERY, CarrierData}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec get_blocks(ne_binary(), ne_binary(), ne_binary(), knm_search:options()) ->
                        {'ok', list()} |
                        {'error', 'not_available'}.
-ifdef(TEST).
get_blocks(?BLOCK_PHONEBOOK_URL, _Prefix, _Quantity, Options) ->
    format_blocks_resp(?BLOCKS_RESP, Options).
-else.
get_blocks(Url, Prefix, Quantity, Options) ->
    Offset = props:get_binary_value('offset', Options, <<"0">>),
    Limit = props:get_binary_value('blocks', Options, <<"0">>),
    Country = kapps_config:get(?KNM_OTHER_CONFIG_CAT, <<"default_country">>, ?KNM_DEFAULT_COUNTRY),
    ReqBody = <<"?prefix=", (kz_util:uri_encode(Prefix))/binary
                ,"&size=", (kz_util:to_binary(Quantity))/binary
                ,"&offset=", Offset/binary
                ,"&limit=", Limit/binary
              >>,
    Uri = <<Url/binary
            ,"/blocks/", Country/binary
            ,"/search", ReqBody/binary
          >>,
    lager:debug("making request to ~s", [Uri]),
    case kz_http:get(binary:bin_to_list(Uri)) of
        {'ok', 200, _Headers, Body} ->
            format_blocks_resp(kz_json:decode(Body), Options);
        {'ok', _Status, _Headers, Body} ->
            lager:error("block lookup failed: ~p ~p", [_Status, Body]),
            {'error', 'not_available'};
        {'error', Reason} ->
            lager:error("block lookup error: ~p", [Reason]),
            {'error', 'not_available'}
    end.
-endif.

-spec format_blocks_resp(kz_json:object(), knm_search:options()) ->
                                {'bulk', list()} |
                                {'error', 'not_available'}.
format_blocks_resp(JObj, Options) ->
    case kz_json:get_value(<<"status">>, JObj) of
        <<"success">> ->
            QID = knm_search:query_id(Options),
            Numbers =
                lists:flatmap(fun(I) -> format_block_resp_fold(I, QID) end
                             ,kz_json:get_value(<<"data">>, JObj, [])
                             ),
            {'bulk', Numbers};
        _Error ->
            lager:error("block lookup resp error: ~p", [JObj]),
            {'error', 'not_available'}
    end.

format_block_resp_fold(Block, QID) ->
    StartNumber = kz_json:get_value(<<"start_number">>, Block),
    EndNumber = kz_json:get_value(<<"end_number">>, Block),
    [format_found(QID, StartNumber, Block)
    ,format_found(QID, EndNumber, Block)
    ].

%%--------------------------------------------------------------------
%% @private
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec format_acquire_resp(knm_number:knm_number(), kz_json:object()) ->
                                 knm_number:knm_number().
format_acquire_resp(Number, Body) ->
    Num = knm_phone_number:number(knm_number:phone_number(Number)),
    JObj = kz_json:get_value([<<"data">>, Num], Body, kz_json:new()),
    case kz_json:get_value(<<"status">>, JObj) of
        <<"success">> ->
            Routines = [fun maybe_merge_opaque/2
                       ,fun maybe_merge_locality/2
                       ],
            lists:foldl(fun(F, N) -> F(JObj, N) end
                       ,Number
                       ,Routines
                       );
        Error ->
            lager:error("number lookup resp error: ~p", [Error]),
            knm_errors:by_carrier(?MODULE, 'lookup_resp_error', Num)
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec maybe_merge_opaque(kz_json:object(), knm_number:knm_number()) ->
                                knm_number:knm_number().
maybe_merge_opaque(JObj, Number) ->
    case kz_json:get_ne_value(<<"opaque">>, JObj) of
        'undefined' -> Number;
        Opaque ->
            PN = knm_phone_number:set_carrier_data(knm_number:phone_number(Number), Opaque),
            knm_number:set_phone_number(Number, PN)
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% @end
%%--------------------------------------------------------------------
-spec maybe_merge_locality(kz_json:object(), knm_number:knm_number()) ->
                                  knm_number:knm_number().
maybe_merge_locality(JObj, Number) ->
    case kz_json:get_ne_value(<<"locality">>,  JObj) of
        'undefined' -> Number;
        Locality ->
            PN = knm_phone_number:set_feature(knm_number:phone_number(Number)
                                             ,<<"locality">>
                                             ,Locality
                                             ),
            knm_number:set_phone_number(Number, PN)
    end.
