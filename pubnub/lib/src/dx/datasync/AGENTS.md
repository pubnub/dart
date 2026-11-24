# DataSync guide

DataSync stores typed objects on a subscribe key and announces changes to them in real time. The SDK exposes CRUD for five object kinds through `pubnub.dataSync`, plus real-time handles that subscribe to changes. Read `../AGENTS.md` first: DataSync follows the same Params / Result / `defaultFlow` pattern, at a larger scale.

## Key files

| File | Contents |
| --- | --- |
| `datasync.dart` | `DataSyncDx`, the façade exposed as `PubNub.dataSync`. For each of entity, relationship, user, channel, and membership it has `createX`, `getXs` (list), `getX`, `setX` (full replace), `updateX` (JSON Patch), and `removeX`. |
| `schema.dart` | Wire types written by hand: `XInput` (create), `XUpdate` (set), `XRecord` (decoded object), `DataSyncPage`, `DataSyncLinks`, `JsonPointerPair`, `ClassLevel`. |
| `subscribable.dart` | `DataSyncSubscribable` with `DataSyncUser`, `DataSyncChannel`, `DataSyncEntity`. Created by `PubNub.dataSyncUser/dataSyncChannel/dataSyncEntity` in `../../default.dart`. |
| `../_endpoints/datasync/{entity,relationship,user,channel,membership}.dart` | `XParams` / `XResult` for every operation. |
| `../../subscribe/projection.dart` | `normalizeProjection` and `projectionChannel` (`@nodoc`). |
| `../../subscribe/events.dart` | `DataSyncEvent`, `DataSyncEventType`, `DataSyncObjectType`. |

## Families

| Family | Endpoint file | Path tail | Create/set content type | List class query |
| --- | --- | --- | --- | --- |
| Entity | `entity.dart` | `entities` | `application/vnd.pubnub.objects.entity+json;version=1` | `entity_class`, required |
| Relationship | `relationship.dart` | `relationships` | `application/vnd.pubnub.objects.relationship+json;version=1` | `relationship_class`, required; filters `entity_a_id`, `entity_b_id` |
| User | `user.dart` | `users` | `application/vnd.pubnub.objects.user+json;version=1` | `entity_class`, optional |
| Channel | `channel.dart` | `channels` | `application/vnd.pubnub.objects.channel+json;version=1` | `entity_class`, optional |
| Membership | `membership.dart` | `memberships` | `application/vnd.pubnub.objects.membership+json;version=1` | no class name; filters `user_id`, `channel_id` |

- Every family's update uses `application/json-patch+json`. The public delete verb is `remove*`; there is no `delete*` method.
- Entity and relationship class names are required (`Ensure(...).isNotEmpty`). User and channel class names may be omitted, and the server defaults them to `User` and `Channel`.

## Wire names

- Input `className` and `classVersion` are stored as `entityClass` and `entityClassVersion`, or `relationshipClass` and `relationshipClassVersion` for relationships. To patch the version, use the stored name (`/entityClassVersion`), not `classVersion`.
- `ClassLevel.global` is sent as `'Global'`, `ClassLevel.subKey` as `'SubKey'`.
- A membership is a relationship. Its class fields are `relationshipClass` and `relationshipClassVersion`, and its input has `userId` and `channelId` instead of a class name.
- `UserRecord` and `ChannelRecord` are their own types, not aliases of `EntityRecord`. `DataSyncChannel` (the subscribe handle) is not the Objects `Channel` or `ChannelMetadata`.

## Request conventions

- Paths start with `v1/datasync/subkeys/{subscribeKey}/…`. `defaultFlow` adds `uuid`, `auth`, and the signature; the params do not.
- Create and set bodies are `{"data": <input.toJson()>}`, JSON-encoded **before** the params are built (`await _core.parser.encode({'data': input})`), so `defaultFlow` can sign the string.
- Set replaces the resource. Class identity is immutable and absent from `*Update`. `toJson` omits null fields, so an omitted payload is not sent and the server clears it; an explicit empty map is sent as `{}`.
- Update bodies are the bare RFC 6902 patch array, not wrapped in `data`. `buildJsonPatch` (`schema.dart`) emits operations in a fixed order (add, replace, remove, move, copy, test). `add`, `replace`, and `test` always include `value`, even `null`. Paths are RFC 6901 pointers sent verbatim, with no `/payload` prefix added. At least one operation is required.
- `setX` and `updateX` accept `ifMatchesEtag`, sent as `If-Match` only when non-empty. Pass `record.eTag` back.
- Lists:
  - `classVersion` is a query parameter only when non-null; it is never sent as `0`.
  - `filterFast` (`filter_fast`, strongly consistent) and `filter` (eventually consistent) are both sent when both are set. The SDK does not reject the combination; do not add that check unless asked.
  - Pagination is a forward cursor: `DataSyncPage.nextCursor` and `hasNext` come from `meta.next_cursor` and `meta.has_next`. Pass `nextCursor` back as `cursor`.
  - The client sets no default `limit`.
  - All-optional queries pass `null` instead of an empty map, so the URL has no trailing `?`.

## Errors

DataSync failures carry an `errors` array. `../_utils/exceptions.dart` turns it into `DataSyncException.fromErrors(errors, statusCode:)` (`../../core/exceptions.dart`), which exposes `errorCode`, `errorMessage`, `path`, `statusCode`, and the full `errors` list.

- `errorCode` (`DS-0100`, …) is the stable value to branch and assert on; `errorMessage` is not. A missing code is `DataSyncException.unknownErrorCode` (`'unknown'`).
- `MalformedResponseException` means a success body whose required fields have the wrong shape (`_required` in `schema.dart`).

## Real-time

- `pubnub.dataSyncEntity(id).subscription(projection: 'admin')` returns an inactive subscription to the projection channel `__admin__<id>`; call `subscribe()` on it. The base projection (`null`, empty, `default`, `__default__`) subscribes to `<id>` itself. The `withProjection:` parameter of `PubNub.subscribe` and `PubNub.subscription` performs the same mapping for plain channel names.
- Ids, including wildcards such as `user.*`, are used verbatim. Do not pass an id that already carries a projection prefix.
- Change events arrive as `MessageType.dataSync` (`e: 5`). They become a `DataSyncEvent` only when `metadata.source` is `data-sync` and `metadata.event` and `metadata.type` are non-empty strings. Any other type-5 payload is an ordinary `MessageEvent`. Consumers read events from `Subscription.dataSync` or the `events` stream.
- A recognized DataSync payload whose `data` is not a map, or whose `data.id` is not a string, is dropped. Delete events still need `data.id`.
- `metadata.type` maps to `DataSyncObjectType`. When the system class is `user`, `channel`, or `membership` (case-insensitive), the type is rewritten to that built-in kind. The retired positional class form (`User::`, `::Lion`) is still accepted.
- `metadata.version` is stored on `DataSyncEvent.version` but never used to accept or reject an event.
- All subscriptions on one keyset share a single subscribe loop; match events on `channel`, which is the projection channel when a projection is set.

## Access Manager mapping

Grant encoding is in `../pam/resource.dart` and `../pam/token_request.dart`.

- **Permissions.** `ResourceType.entity`, `relationship`, and `membership` encode as `datasync:entities`, `datasync:relationships`, and `datasync:memberships`. DataSync users and channels do **not** use the prefix: `ResourceType.user` encodes as `users` and `ResourceType.channel` as `channels`. `ResourceType.uuid` is App Context uuid metadata and does not authorize a DataSync user.
- **Projections.** Projection scopes use `datasync:` for every kind, including `datasync:users` and `datasync:channels`. Assign them with `TokenRequest.addDataSyncProjection`. They are stored in the token's `pn-projections` meta, the base projection is the exported constant `defaultProjection` (`'__default__'`), and a projection grants no permission by itself.
- Keep both mappings in step with any new DataSync object kind.

## Adding an operation or object kind

1. Add the wire types to `schema.dart` next to the existing kind they most resemble. Mirror its `toJson` / `fromJson`.
2. Add `XParams` / `XResult` to `../_endpoints/datasync/<kind>.dart`, reusing that file's content-type constants.
3. Add the method to `DataSyncDx`, keeping the existing order: create, get list, get, set, update, remove.
4. Export the new public types from `lib/pubnub.dart`, with `{@category DataSync}` on each class.
5. Unit tests: `test/unit/dx/datasync/<kind>_test.dart` using `test/unit/dx/datasync/_helpers.dart` (`newClient`, `dsPath`, `contentType`, `body`, `dataBody`, and the payload builders).
6. Integration tests: `test/integration/datasync/` using `test/integration/datasync/_helpers.dart` (`testClient`, `freshId`, `runMarker`, `Cleanup`, `eventTimeout`, `throwsDataSync`). The keyset must already provide the classes used there. These tests need `DS_PUBLISH_KEY`, `DS_SUBSCRIBE_KEY`, and `DS_SECRET_KEY` and fail, rather than skip, without them.
7. Snippets go in `example/datasync.dart`.

## Pitfalls

- The service rejects `_` in ids (DS-0004). Test ids come from `freshId(prefix)`, which only adds a numeric suffix, so prefixes must not contain `_`.
- `datasync.dart` is large. Edit the section for one kind at a time, and keep the methods for all kinds structurally identical, so a reviewer can diff them against each other.
