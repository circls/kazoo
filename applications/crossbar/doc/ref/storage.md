### Storage

#### About Storage

#### Schema

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`attachments` | Defines where and how to store attachments | [#/definitions/storage.attachments](#storageattachments) |   | `false`
`connections` | Describes alternative connections to use (such as alternative CouchDB instances | [#/definitions/storage.connections](#storageconnections) |   | `false`
`id` | ID of the storage document | `string` |   | `false`
`plan` | Describes how to store documents depending on the database or document type | [#/definitions/storage.plan](#storageplan) |   | `false`


##### storage.attachment.aws

schema for AWS attachment entry

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`handler` | What AWS service to use | `string('s3')` |   | `true`
`name` | Friendly name for this configuration | `string` |   | `false`
`settings` | AWS API settings | `object` |   | `true`
`settings.bucket` | Bucket name to store data to | `string` |   | `true`
`settings.host` | Region-specific hostname to use, if applicable | `string` |   | `false`
`settings.key` | AWS Key to use | `string` |   | `true`
`settings.path` | Custom path to use as a prefix when saving files | `string` |   | `false`
`settings.secret` | AWS Secret to use | `string` |   | `true`

##### storage.attachment.google_drive

schema for google drive attachment entry

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`handler` | What handler module to use | `string('google_drive')` |   | `true`
`name` | Friendly name for this configuration | `string` |   | `false`
`settings` | Settings for the Google Drive account | `object` |   | `true`
`settings.folder_id` | Folder ID in which to store the file, if any | `string` |   | `false`
`settings.oauth_doc_id` | Doc ID in the system 'oauth' database | `string` |   | `true`

##### storage.attachments

Keys are 32-character identifiers to be used in storage plans

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------

##### storage.connection.couchdb

schema for couchdb connection entry

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`driver` |   | `string('kazoo_couch')` |   | `true`
`name` |   | `string` |   | `false`
`settings` |   | `object` |   | `true`
`settings.connect_options` |   | `object` |   | `false`
`settings.connect_options.keepalive` |   | `boolean` |   | `false`
`settings.connect_timeout` |   | `integer` |   | `false`
`settings.credentials` |   | [#/definitions/#/definitions/credentials](##/definitions/credentials) |   | `false`
`settings.ip` |   | `string` |   | `true`
`settings.max_pipeline_size` |   | `integer` |   | `false`
`settings.max_sessions` |   | `integer` |   | `false`
`settings.pool` |   | [#/definitions/#/definitions/pool](##/definitions/pool) |   | `false`
`settings.port` |   | `integer` |   | `true`

##### storage.connections

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------

##### storage.plan

schema for storage plan

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`account` |   | [#/definitions/storage.plan.database](#storageplan.database) |   | `false`
`modb` |   | [#/definitions/storage.plan.database](#storageplan.database) |   | `false`
`system` |   | [#/definitions/storage.plan.database](#storageplan.database) |   | `false`

##### storage.plan.database

schema for database storage plan

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`attachments` |   | [#/definitions/storage.plan.database.attachment](#storageplan.database.attachment) |   | `false`
`connection` |   | `string` |   | `false`
`database` |   | [#/definitions/#/definitions/database](##/definitions/database) |   | `false`
`types` |   | `object` |   | `false`
`types.call_recording` |   | [#/definitions/storage.plan.database.document](#storageplan.database.document) |   | `false`
`types.fax` |   | [#/definitions/storage.plan.database.document](#storageplan.database.document) |   | `false`
`types.mailbox_message` |   | [#/definitions/storage.plan.database.document](#storageplan.database.document) |   | `false`
`types.media` |   | [#/definitions/storage.plan.database.document](#storageplan.database.document) |   | `false`

##### storage.plan.database.attachment

schema for attachment ref type storage plan

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`handler` |   | `string` |   | `false`
`params` |   | `object` |   | `false`
`stub` |   | `boolean` |   | `false`

##### storage.plan.database.document

schema for document type storage plan

Key | Description | Type | Default | Required
--- | ----------- | ---- | ------- | --------
`attachments` |   | [#/definitions/storage.plan.database.attachment](#storageplan.database.attachment) |   | `false`
`connection` |   | `string` |   | `false`

#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/storage

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage
```

#### Create

> PUT /v2/accounts/{ACCOUNT_ID}/storage

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage
```

#### Change

> POST /v2/accounts/{ACCOUNT_ID}/storage

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage
```

#### Patch

> PATCH /v2/accounts/{ACCOUNT_ID}/storage

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage
```

#### Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/storage

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage
```

#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/storage/plans

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage/plans
```

#### Create

> PUT /v2/accounts/{ACCOUNT_ID}/storage/plans

```shell
curl -v -X PUT \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage/plans
```

#### Fetch

> GET /v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}

```shell
curl -v -X GET \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}
```

#### Change

> POST /v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}

```shell
curl -v -X POST \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}
```

#### Patch

> PATCH /v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}

```shell
curl -v -X PATCH \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}
```

#### Remove

> DELETE /v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}

```shell
curl -v -X DELETE \
    -H "X-Auth-Token: {AUTH_TOKEN}" \
    http://{SERVER}:8000/v2/accounts/{ACCOUNT_ID}/storage/plans/{STORAGE_PLAN_ID}
```

