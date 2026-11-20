# DataSync

Conventions for the DataSync data-plane API. Confirm details against current code. Per-method dartdoc already describes each call — follow peers in `lib/src/dx/datasync/` and `lib/src/dx/_endpoints/datasync/` rather than inventing a shape.

Shared endpoint, error, and test rules still apply: [endpoints.md](endpoints.md), [errors.md](errors.md), [testing.md](testing.md). Subscribe delivery is [subscribe.md](subscribe.md).

This is not Objects / App Context. Objects uses `pubnub.objects`, `/v2/objects/...`, and uuid/channel metadata types. DataSync uses `pubnub.dataSync`, `/v1/datasync/subkeys/{subscribeKey}/...`, and the types below. Tests named `app_context_*` cover Objects.

## Surface

Callers use `pubnub.dataSync` (`DataSyncDx`). Realtime handles are separate: `pubnub.dataSyncUser(id)`, `dataSyncChannel(id)`, `dataSyncEntity(id)`. Those handles only subscribe; they do not CRUD.

Five families, each with Create, Get, Get-all, Set (PUT), Update (PATCH), Remove:

| Family | File | Path tail | Create/Set content type | List class query |
|---|---|---|---|---|
| Entity | `entity.dart` | `entities` | `application/vnd.pubnub.objects.entity+json;version=1` | `entity_class` required |
| Relationship | `relationship.dart` | `relationships` | `application/vnd.pubnub.objects.relationship+json;version=1` | `relationship_class` required |
| User | `user.dart` | `users` | `application/vnd.pubnub.objects.user+json;version=1` | `entity_class` optional |
| Channel | `channel.dart` | `channels` | `application/vnd.pubnub.objects.channel+json;version=1` | `entity_class` optional |
| Membership | `membership.dart` | `memberships` | `application/vnd.pubnub.objects.membership+json;version=1` | no class name; optional `user_id`, `channel_id` |

PATCH content type for every family is `application/json-patch+json`. The public method is `remove*`. There is no `delete*` method.

Wire names differ from Dart constructor names:

- Input `className` / `classVersion` are stored as `entityClass` / `entityClassVersion` (relationship: `relationshipClass` / `relationshipClassVersion`). Patch the stored name (`/entityClassVersion`), not `classVersion`.
- `ClassLevel.global` is `'Global'`, `ClassLevel.subKey` is `'SubKey'`.
- Membership is a relationship. Its class fields are `relationshipClass` / `relationshipClassVersion`. Input has `channelId` and `userId`, not a class name. List query uses `relationship_class_version`, `user_id`, `channel_id`.
- Relationship list filters are `entity_a_id` and `entity_b_id`.
- User and channel `className` may be omitted. The server defaults to `User` or `Channel`. Entity and relationship class names are required (`Ensure(...).isNotEmpty`).

`UserRecord` and `ChannelRecord` are their own types with `entityClass` fields. They are not typedefs of `EntityRecord`. `DataSyncChannel` (the subscribe handle) is not Objects `Channel` or `ChannelMetadata`.

## Set, update, and concurrency

Create and set bodies are `{"data": <input.toJson()>}`. Update bodies are the patch array itself, not wrapped in `data`.

Set replaces the resource. Class identity is immutable and is absent from `*Update`. `toJson` omits `payload`, `status`, `id`, and `classLevel` when null, so an omitted payload is not sent and the server clears it. An explicit empty map is sent as `{}`.

Update is RFC 6902 via `buildJsonPatch` in `schema.dart`. Operations are emitted in a fixed order: add, replace, remove, move, copy, test. `add` / `replace` / `test` always include `value`, including null. Paths are RFC 6901 pointers and are sent verbatim: no `/payload` prefix is added, and `.` is not a separator. At least one operation is required.

`If-Match` is set only when `ifMatchesEtag` is non-empty. The response field is `eTag`. Pass `record.eTag` back as `ifMatchesEtag`.

## Lists

`classVersion` is a query parameter only when non-null. It is not written as `0`.

`filterFast` (`filter_fast`, strongly consistent, fewer conditions) and `filter` (`filter`, eventually consistent) are both sent when both are non-empty. This SDK does not reject the combination locally. Do not add that check unless the task asks.

Pagination is a forward cursor. `DataSyncPage.nextCursor` / `hasNext` come from `meta.next_cursor` and `meta.has_next`. Pass `nextCursor` back as `cursor`. `links` is parsed when the body contains a map. Empty query maps are omitted so the URL has no trailing `?`.

Limit is not defaulted in the client. Dartdoc states the server default is 20 and the maximum is 100.

## Events

Events are not a REST call. Message type `5` (`MessageType.dataSync`) whose payload `metadata.source` is `data-sync` and whose `metadata.event` and `metadata.type` are non-empty strings is a `DataSyncEvent` on `Subscription.dataSync`. Any other type-5 payload is a `MessageEvent`. A recognized DataSync payload with a bad `data` shape (`data` not a map, or `data.id` not a string) is dropped.

`metadata.version` is stored on `DataSyncEvent.version`. It is not used to accept or reject the event.

`metadata.type` maps to `DataSyncObjectType`. When the type is `entity` or `relationship` and the system class is `user`, `channel`, or `membership` (case-insensitive), the object type is rewritten to that built-in kind. The retired positional class form (`User::`, `::Lion`) is still accepted: the class name is the last non-empty segment.

Delete events still require `data.id`. `deletedAt`, and for membership `channelId` / `userId`, and for relationship `entityAId` / `entityBId`, are read from that same `data` map.

Subscribe to the resource id. A projection other than the base one uses channel `__{projection}__{id}` (`projectionChannel` in `lib/src/subscribe/projection.dart`). The admin projection is the name `admin`, which produces `__admin__{id}`. Every subscription on one keyset shares a single subscribe loop; match events on `channel`.

Handles: `dataSyncUser(id).subscription(projection: ...)` returns an inactive `Subscription`. Call `subscribe()` on it. `pubnub.subscribe` resumes immediately. Ids are verbatim, including wildcards such as `user.*`. Do not pass an id that already includes a projection prefix.

## PAM

Grant encoding lives in `lib/src/dx/pam/resource.dart` and `token_request.dart`.

- `ResourceType.entity`, `relationship`, and `membership` encode as `datasync:entities`, `datasync:relationships`, and `datasync:memberships`. Their permissions are CRUD only: `create`, `get`, `update`, `delete`.
- DataSync users and channels do **not** use those prefixes for permissions. `ResourceType.user` encodes as `users`. `ResourceType.channel` encodes as `channels`. `ResourceType.uuid` is App Context uuid metadata and does not authorize a DataSync user.
- Projections use a `datasync:` scope for every kind, including users and channels (`datasync:users`, `datasync:channels`). Assign them with `TokenRequest.addDataSyncProjection`. The base projection name is `defaultProjection` (`'__default__'`), stored in token meta `pn-projections`. A projection grants no permission by itself.

## Tests

Unit path and header helpers: `pubnub/test/unit/dx/datasync/_helpers.dart`.

Live tests: `pubnub/test/integration/datasync/`. They need `DS_PUBLISH_KEY`, `DS_SUBSCRIBE_KEY`, and `DS_SECRET_KEY` and do not skip when those are unset. Ids must not contain `_`.
