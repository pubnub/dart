# Networking and platform guide

`lib/src/networking/` is the default `INetworkingModule`. On the Dart VM and in Flutter mobile and desktop apps it uses `dart:io` (HTTP/1.1, plus HTTP/2 through `package:http2`). In the browser it uses `XMLHttpRequest` through `package:web` and `dart:js_interop`. This guide also owns the repository's rules for platform-conditional code, which `../parser/` follows as well.

## Key files

| File | Contents |
| --- | --- |
| `networking.dart` | `NetworkingModule({retryPolicy, origin, ssl, enableHttp2})`: origin (default `https://ps.pndsn.com` with `pnsdk=PubNub-Dart/<version>`), a `Pool(10)` cap on concurrent requests, `register` (installs the supervisor diagnostic and strategy), and `dispose()`. |
| `request_handler/request_handler.dart` | Conditional export of `stub.dart`, `io.dart`, or `web.dart`. |
| `request_handler/io.dart` | `dart:io` handler. `_shouldUseHttp2` picks HTTP/2 only for `https`, with `enableHttp2` on, no injected client, and no proxy. `disposeTransport`. |
| `request_handler/io_connection_manager.dart` | `Http2ConnectionManager`: one per module, held in an `Expando`, with fallback to HTTP/1.1 when ALPN negotiation fails. |
| `request_handler/web.dart` | Browser handler on `package:web` `XMLHttpRequest`. |
| `response/`, `meta/diagnostics/` | Platform-specific response wrappers and network-failure diagnostics, using the same conditional-export pattern. |
| `meta/strategy.dart` | `NetworkingStrategy`: retries subscribe requests only, using `RetryPolicy`. Every other request fails immediately. |
| `utils.dart` | `prepareUri` and other shared helpers. |
| `../parser/big_int_json.dart` | Conditional export of `quoteBigIntegers`. The web variant quotes integers of 16 digits or more before decoding, so timetokens keep full precision; the `dart:io` variant returns its input unchanged. History and subscribe timetokens depend on it. |

## Platform-conditional code

The only accepted pattern is a conditional **export** with three variants:

```dart
export 'stub.dart'
    if (dart.library.io) 'io.dart'
    if (dart.library.js_interop) 'web.dart';
```

- `stub.dart` declares the same top-level API and throws, or does nothing. It exists only so that analysis has a default.
- `io.dart` may import `dart:io` and `package:http2`. `web.dart` may import `dart:js_interop` and `package:web`. A helper that only one variant imports, such as `io_connection_manager.dart`, follows that variant's rules. No other file in the package may import any of these.
- Every variant must expose the same names and signatures. When you add a member to one, add it to all three.
- Do not use `dart:html`, `dart:js`, `dart:js_util`, or `package:js`. They break dart2wasm compilation.
- After changing any variant, run `dart analyze --fatal-warnings lib` and the browser test in `AGENTS.md`.

## Invariants

- `Request.uri` has no host when it leaves the feature layer. `prepareUri` joins it with `getOrigin()`. Do not hard-code hosts in features. The only exception is the Files upload URL returned by the service, which arrives fully qualified.
- `PubNub.dispose()` must keep calling `NetworkingModule.dispose()`, which closes pooled HTTP/2 connections. `INetworkingModule` declares no `dispose`, so `PubNub.dispose()` type-checks for `NetworkingModule`; a custom networking module is not disposed. Keep the interface unchanged rather than adding `dispose` to it, which would break consumers who implement it.
- Browsers reject certain request headers. `isHeaderForbidden` (`utils.dart`) lists them, and `request_handler/web.dart` skips them; do not rely on such a header reaching the server from the web.
- Per-request timeouts come from `RequestType` (`../core/net/request_type.dart`). Subscribe uses a 300-second long-poll timeout; do not shorten it in the handler.
- Do not add logging or exception messages that include `auth`, `signature`, or token values.
- Integers above 2^53 lose precision as JavaScript numbers. Parse timetokens as `BigInt`.

## Testing

- Unit tests replace this module with `FakeNetworkingModule` (`test/unit/net/fake_net.dart`). `test/unit/net/http2_headers_test.dart` covers HTTP/2 header handling and is `@TestOn('vm')`.
- Platform checks: `test/integration/networking/` (`networking_test.dart`, `http2_test.dart`, VM), and `test/integration/web_compatibility_test.dart` (`@TestOn('browser')`), which runs with `dart test -p chrome …`.
