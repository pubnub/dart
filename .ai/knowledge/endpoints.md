# HTTP endpoints

How request endpoints are implemented in this SDK. Prefer existing peers in the same feature area over inventing structure. Confirm details against current code when they matter.

Shared error and test rules: [errors.md](errors.md), [testing.md](testing.md).

## Core pattern

There is no endpoint interface with `validate` / `buildPath` / `buildQuery`. A call is three pieces:

1. `*Params extends Parameters` with `toRequest()` (and `toJson()` when the call is logged).
2. A method on a `*Dx` mixin or service that validates, resolves the keyset, encodes the body, and calls `defaultFlow`.
3. `*Result extends Result` with a private constructor and `factory fromJson`.

`Parameters` and `Result` live in `lib/src/core/endpoint.dart`. `Request` factories are `Request.get/post/put/patch/delete/subscribe/file` (`lib/src/core/net/request.dart`). `RequestType.file` is still HTTP POST.

Typical service method (see `PublishDx.publish` or `DataSyncDx.createEntity`):

1. `Ensure(...)` on required arguments.
2. `keyset ??= keysets[using]` or `_core.keysets[using]`.
3. `await core.parser.encode(...)` for JSON bodies. Pass the encoded `String` as `Request` `body`.
4. `defaultFlow<Params, Result>(keyset:, core:, params:, serialize:)`.
5. `serialize` is `(object, [_]) => Result.fromJson(object)`. The optional second argument is response headers; use it only when a peer does.

`defaultFlow` (`lib/src/dx/_utils/default_flow.dart`):

- Runs inside a `Fiber`, so networking retry policy applies.
- When the request URI has an empty authority and a keyset is passed, it adds `uuid` and, when `keyset.hasAuth()` and the path does not contain `grant`, `auth` (`token` if set, otherwise `authKey`).
- When `secretKey` is set and the body is a `String` or null, it adds `timestamp` (unix seconds) and a PAM v2 `signature` (`computeV2Signature`). Binary bodies are not signed here.
- Sends the request through `core.networking.handler()`.
- On success, JSON-decodes unless `deserialize: false` (file download).
- On `RequestFailureException`, decodes JSON, or XML when the body starts with `<?xml` or the request type is `file`, then throws `getExceptionFromAny`.

New endpoints leave `uuid`, `auth`, and `signature` to `defaultFlow`. DataSync params do this. Some older peers, such as publish, still put `uuid` and `auth` on the request themselves; do not strip those just to match the newer pattern. Subscribe does not use `defaultFlow`, and `SubscribeParams.toRequest()` adds `uuid`, `auth`, and `signature` itself.

## Where code goes

| Piece | Location |
|---|---|
| Client methods (publish, signal, presence, PAM, push, message actions, time) | mixin `*Dx on Core` under `lib/src/dx/<feature>/` |
| Grouped APIs | class holding `Core`: `BatchDx`, `ChannelGroupDx`, `ObjectsDx`, `FileDx`, `DataSyncDx` |
| Request and result types | `lib/src/dx/_endpoints/<feature>.dart` |
| DataSync requests | `lib/src/dx/_endpoints/datasync/<family>.dart` — one file per family, all verbs in that file |
| Objects (App Context) requests | `lib/src/dx/_endpoints/objects/` |
| Domain models | `schema.dart` next to the feature (`datasync/schema.dart`, `objects/schema.dart`, `files/schema.dart`) |

The feature library exports its `_endpoints` file. `lib/pubnub.dart` then re-exports only the public names through a `show` list. Adding a public class or method requires that `show` entry. `*Params` types stay off the list.

Path prefixes already in the tree:

- Publish: `/publish/{publishKey}/{subscribeKey}/0/{channel}/0/{message}`
- Subscribe: `/v2/subscribe/{subscribeKey}/{channels}/0` (built only by `SubscribeParams`)
- Objects / App Context: `/v2/objects/{subscribeKey}/uuids|channels/...`
- DataSync: `/v1/datasync/subkeys/{subscribeKey}/{entities|relationships|users|channels|memberships}`

Objects and DataSync both talk about users, channels, and memberships. They are not interchangeable. DataSync rules are in [datasync.md](datasync.md).

## Query and body habits

- Build query maps with collection-`if`. Omit a key when the value is null or, where peers do, empty. Do not send an unset integer as `0`.
- An empty query map renders a trailing `?`. Peers that have an all-optional query pass `null` instead of `{}` (see `GetUsersParams`).
- `Uri` encodes query values. Tests compare decoded query parameters, so expected paths in `when(...)` use already-encoded strings only when asserting the raw path.
- Conditional headers (`If-Match`, `Content-Type`) are set on the `Request`, not in `defaultFlow`.
- Vendor content types are constants at the top of the endpoint file. Match the peer family instead of using `application/json`.

## Platform splits

These libraries are conditional exports: `stub.dart` by default, `io.dart` when `dart.library.io` is available, `web.dart` when `dart.library.js_interop` is available.

- `lib/src/networking/request_handler/request_handler.dart`
- `lib/src/networking/response/response.dart`
- `lib/src/networking/meta/diagnostics/diagnostics.dart`
- `lib/src/parser/big_int_json.dart`

A transport change usually needs all three of stub, io, and web. HTTP/2 (`NetworkingModule.enableHttp2`, default true) exists only on `dart:io`. Web uses the browser stack. `quoteBigIntegers` keeps 16+ digit integers precise on web; native parsing is an identity function. History and subscribe timetokens depend on that.

`PubNub.dispose()` closes pooled HTTP/2 connections only when `networking` is a `NetworkingModule`. The `INetworkingModule` interface does not declare `dispose`.

## Networking defaults

`NetworkingModule` origin is `https://ps.pndsn.com` with query `pnsdk=PubNub-Dart/${Core.version}`. Retry policy defaults to `RetryPolicy.exponential()` and is registered as a supervisor strategy. Subscribe uses `RequestType.subscribe` (long timeouts) and its own loop; it is not retried by the `Fiber` inside `defaultFlow`.

Forbidden browser headers are listed in `lib/src/networking/utils.dart` (`isHeaderForbidden`). Do not add those header names on web requests.
