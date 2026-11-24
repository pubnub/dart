# Feature layer (dx) guide

`lib/src/dx/` holds every consumer-facing REST feature. Each feature turns a typed API call into a `Request`, runs it through `defaultFlow`, and decodes the response into a typed `Result`. Real-time subscribe lives in `../subscribe/`. DataSync has its own guide in `datasync/AGENTS.md`.

## Layout

| Path | Contents |
| --- | --- |
| `<feature>/<feature>.dart` | The API surface for one feature: `publish/`, `signal/`, `presence/`, `message_action/`, `push/`, `pam/`, `files/`, `objects/`, `channel/`, `batch/`, `datasync/`, `supervisor/`. |
| `time.dart`, `logging_configuration.dart` | `TimeDx`, and `PubNubLogging` with `LoggingConfiguration`. |
| `_endpoints/` | One file per feature (subfolders for `objects/` and `datasync/`) with `XParams extends Parameters` and `XResult extends Result`. Feature files re-export their endpoint file. |
| `_utils/` | `defaultFlow`, `Ensure` / `InvariantException`, `computeV2Signature`, error mapping (`exceptions.dart`), `DefaultResult`, `file_validation.dart`. Barrel: `_utils/utils.dart`. |

## Two API shapes

1. **Mixin on `Core`**: `mixin PublishDx on Core`. It is mixed into `PubNub` in `../default.dart` (`TimeDx`, `PublishDx`, `SubscribeDx`, `SignalDx`, `MessageActionDx`, `PushNotificationDx`, `PamDx`, `PresenceDx`, `SupervisorDx`, `PubNubLogging`), so its methods are called as `pubnub.publish(...)`.
2. **Façade class holding `Core`**: `BatchDx`, `ChannelGroupDx`, `ObjectsDx`, `FileDx`, `DataSyncDx`. Each is a `late final` field on `PubNub`, initialized in its constructor and called as `pubnub.files.sendFile(...)`.

Use a mixin for a handful of top-level calls. Use a façade for a feature with many related operations.

## Method skeleton

Every API method follows the same sequence (see `publish/publish.dart`):

```dart
Future<XResult> doThing(String channel, {Keyset? keyset, String? using}) async {
  Ensure(channel).isNotEmpty('channel name');      // 1. validate → InvariantException
  keyset ??= keysets[using];                       // 2. resolve keyset → KeysetException
  Ensure(keyset.publishKey).isNotNull('publishKey');

  var params = XParams(keyset, channel);           // 3. build params
  _logger.fine(LogEvent(                           // 4. log parameters
      message: 'X with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo));

  return defaultFlow<XParams, XResult>(            // 5. run
      keyset: keyset,
      core: this,
      params: params,
      serialize: (object, [_]) => XResult.fromJson(object));
}
```

- `XParams` holds the inputs, a `toJson()` used only for logging, and `toRequest()`. `toRequest()` builds `Request.get/post/…(uri: Uri(pathSegments: [...], queryParameters: {...}), body:, headers:)` with **no host**. The networking module fills in the origin.
- `XResult` has a private constructor and a hand-written `factory XResult.fromJson(dynamic object)`.

## `defaultFlow` (`_utils/default_flow.dart`)

1. Wraps the call in a `Fiber` tagged with the request's `RequestType`, so supervisor retry rules apply.
2. Adds `uuid`, and `auth` from `PamKeysetExtension.getAuth` (token or authKey) except on `grant`, to requests without a host.
3. When the keyset has a `secretKey` and the body is a `String` or `null`, adds `timestamp` and a v2 `signature` (`_utils/signature.dart`).
4. Runs the request through `core.networking.handler()`, then decodes the response with `core.parser.decode` and calls `serialize`. Pass `deserialize: false` to receive the raw response instead.
5. On `RequestFailureException`, decodes the error body (XML for `RequestType.file` or `<?xml` bodies) into `DefaultResult`, then throws `getExceptionFromAny(...)` (`_utils/exceptions.dart`). See Errors and validation below.

New endpoints leave `uuid`, `auth`, and `signature` to `defaultFlow`, as the DataSync params do. Older peers, such as publish, still put `uuid` and `auth` on the request themselves; do not strip those to match the newer pattern. Subscribe never uses `defaultFlow`; see `../subscribe/AGENTS.md`.

## Request conventions

- Build query maps with collection-`if`, and omit a key when its value is `null` (or empty, where peers do). Never send an unset integer as `0`.
- An empty query map renders a trailing `?`. When every query parameter is optional, pass `null` instead of `{}`, as `GetUsersParams` does (`_endpoints/datasync/user.dart`).
- JSON bodies are encoded before the params are built (`await parser.encode(...)`), and the `String` is passed as the `Request` body, so `defaultFlow` can sign it.
- Set conditional headers (`If-Match`, `Content-Type`) on the `Request`, not in `defaultFlow`. Keep vendor content types as constants at the top of the endpoint file, and match the peer family rather than using `application/json`.
- `RequestType.file` is still an HTTP POST. It selects XML error decoding and the 30-second timeouts.
- `serialize`'s optional second argument is the response headers. Use it only when a peer does.
- Take paths, query names, content types, and status semantics from the task or the nearest peer. Never invent them.

Path prefixes in the tree:

| API | Path |
| --- | --- |
| Publish | `publish/{publishKey}/{subscribeKey}/0/{channel}/0/{message}` |
| Subscribe | `v2/subscribe/{subscribeKey}/{channels}/0` (built only by `SubscribeParams`) |
| Objects (App Context) | `v2/objects/{subscribeKey}/uuids/...`, `v2/objects/{subscribeKey}/channels/...` |
| DataSync | `v1/datasync/subkeys/{subscribeKey}/{entities,relationships,users,channels,memberships}` |

Objects and DataSync both have users, channels, and memberships, but they are different APIs. Do not mix their paths, types, or PAM scopes. `test/unit/dx/app_context_test.dart` and `test/integration/app_context/` cover Objects.

## Errors and validation

Validation happens before the request is built, with `Ensure` (`_utils/ensure.dart`). It throws `InvariantException`, whose message comes from a template id:

| Call | Id | Message |
| --- | --- | --- |
| `Ensure(v).isNotNull('channel')` | `not-null` | `channel cannot be null` |
| `Ensure(v).isNotEmpty('class name')` | `not-empty` | `class name cannot be empty` |
| `Ensure(v).isEqual(other, 'field')` | `is-equal` | `field has to equal <other>` |
| `Ensure.fail('not-together', 'name', ['pattern'])` | `not-together` | `name and pattern can not be provided together` |
| `Ensure.fail('invalid-type', ...)` | `invalid-type` | `<that> must be either <a> or <b>.` |

- `isNotEmpty` accepts only a non-empty `String` or `List`; a `Map` always fails it. `null` and empty are different checks.
- Do not change the message templates. Add a new id next to them when new wording is needed.
- Keyset lookup throws `KeysetException` from `KeysetStore`, not `InvariantException`.

`getExceptionFromAny` maps failed responses:

| Error body | Exception |
| --- | --- |
| `status 400`, message `Invalid Arguments` | `InvalidArgumentsException` (the core one) |
| `status 403`, message starting `Use of the history Delete API` | `MethodDisabledException` |
| `status 403`, message `Forbidden`, `Token is expired.`, or `Token is revoked.` | `ForbiddenException(service, reason)` |
| Non-empty `errors` list (DataSync) | `DataSyncException.fromErrors` |
| JSON list of 3 elements | `PublishException(list[1])`; an empty list is `UnknownException` |
| XML document (Files) | `PubNubException('Request failed. Details: ...')` |
| Anything else | `PubNubException('<status> error: <message>')` or `PubNubException('unknown exception ...')` |

- Do not throw a new exception type from an endpoint that already goes through this mapper unless the task asks for one. Add new error shapes to the mapper.
- `MalformedResponseException` is for a success body whose required fields have the wrong shape, not for HTTP errors.
- Publish can also answer HTTP 200 with `PublishResult.isError == true`. That path does not throw.
- A Dart `Error` thrown inside a `Fiber` fails the call at once and is never retried. Only `Exception`s reach the supervisor.

## Publish trace

`publish/publish.dart` `PublishDx.publish` validates and resolves the keyset, then encodes the message with `parser.encode`. When a cipher key or `CryptoModule` is configured, it encrypts the payload and base64-encodes it, then JSON-encodes it again. Next it builds `PublishParams`, where `fire: true` sets `storeMessage = false` and `noReplication = true`. `_endpoints/publish.dart` `PublishParams.toRequest()` produces `GET publish/{pub}/{sub}/0/{channel}/0/{message}` with `store`, `meta`, `norep`, `auth`, `custom_message_type`, `uuid`, and `ttl`. `defaultFlow` runs it, and `PublishResult.fromJson` reads `[1, "Sent", "<timetoken>"]`. `channel/channel.dart` `Channel.publish` is a convenience wrapper over the same call.

## Feature notes

- **Access Manager (`pam/`)**: `requestToken(...)` returns a `TokenRequest` (`token_request.dart`). Callers `add(ResourceType, ...)` resources, patterns, and categories, then call `grantToken(request)`. `parseToken` decodes CBOR (`cbor.dart`, `token.dart`). `setToken` stores the token in keyset settings. The v2 `grant` and `PamGrantResult` are not exported; do not document them.
- **Files (`files/`)**: `FileDx.sendFile` is a multi-step flow. It generates an upload URL, uploads multipart form data with `RequestType.file` to an external URL, then publishes the file message, retrying up to `fileMessagePublishRetryLimit` times. File input is validated in `_utils/file_validation.dart`.
- **Objects (`objects/`)**: App Context metadata for UUIDs, channels, and memberships. Shared include and sort types are in `objects_types.dart`.

## Adding or changing an endpoint

1. Add or extend `XParams` and `XResult` in `_endpoints/<feature>.dart`. Write `toRequest()` and `fromJson` by hand.
2. Add the method to the feature's mixin or façade, following the skeleton above. Validate every required argument with `Ensure`.
3. Export new consumer types from `lib/pubnub.dart` with `show`. Keep `XParams` and other internals unexported and mark them `/// @nodoc` when they are public.
4. Document the public method and result with the `dart-doc-author` skill, adding `{@category <Category>}` to new public classes.
5. Add unit tests with `FakeNetworkingModule` and fixtures under `test/unit/dx/`, following the `dart-test-writer` skill. Cover request construction, response decoding, and each error mapping.
6. Add documentation snippets as described in `AGENTS.md`.
7. Add a new error shape to `_utils/exceptions.dart` instead of handling it in the feature.
8. Keep the change scoped: do not reformat or refactor unrelated endpoints.

## Pitfalls

- There are **two** `InvalidArgumentsException` classes: one in `../core/exceptions.dart` and one in `_utils/file_validation.dart`. `_utils/exceptions.dart` imports core with the prefix `core_exceptions` to disambiguate. Do not add a third, and check which one a test expects.
- `PublishResult.timetoken` is an `int` for historical reasons. New timetoken fields use `Timetoken`.
- `SupervisorDx` (`supervisor/`) is `@nodoc` even though `signals` and `reconnect()` are callable. Do not document it as a feature.
