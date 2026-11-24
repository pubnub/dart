# Core module guide

`lib/src/core/` holds the platform-neutral contracts that every other module builds on. It has no feature logic and no platform code. Every `src/` file reaches it through `import 'package:pubnub/core.dart'`, which re-exports these files without `show` and is `@nodoc`. Only the subset re-exported with `show` from `lib/pubnub.dart` is consumer API.

## Key files

| File | Contents |
| --- | --- |
| `core.dart` | `Core`: `keysets`, `networking`, `parser`, `crypto`, `supervisor`, `Core.version` (release-managed). |
| `keyset/keyset.dart`, `keyset/store.dart` | `Keyset` (keys, `userId`, deprecated `uuid` and `cipherKey`, extension `settings`) and `KeysetStore` (named keysets plus default). |
| `endpoint.dart` | `Parameters` (`toRequest()`) and `Result`, the base types of every endpoint. |
| `net/` | `INetworkingModule`, `IRequestHandler`, `Request` (`Request.get/post/put/patch/delete/subscribe/file`), `RequestType` with per-type timeouts, `IResponse`, request exceptions (`RequestFailureException`, `RequestTimeoutException`, …). |
| `parser.dart` | `IParserModule` and `ParserException`. |
| `crypto/` | `ICryptoModule`, `ICryptor`, `EncryptedData`, `CryptoException`, `CipherKey`. |
| `supervisor/` | `SupervisorModule`, `Fiber`, `Diagnostic`, `Strategy`, `Resolution`, `Signals`, `NetworkIsUpEvent` / `NetworkIsDownEvent`. |
| `policies/retry_policy.dart` | `RetryPolicy` with `linear`, `exponential`, and `none`. |
| `logging/logging.dart` | `ILogger`, `injectLogger`, `provideLogger`, `globalLoggerRegistry`, `Level`, `LogEvent`, `LogEventDetailsType`. |
| `exceptions.dart` | `PubNubException` and its core subclasses. |
| `message/`, `timetoken.dart`, `uuid.dart`, `user_id.dart` | `BaseMessage`, `MessageType`, `Timetoken` (wraps `BigInt`), `UUID`, `UserId`. |

## How it fits

- `Core`'s constructor adds the default keyset, then calls `register(core)` on the networking, parser, and crypto modules. Modules use `register` to keep a reference to `Core` and, for networking, to install supervisor diagnostics and strategies.
- `PubNub` (`../default.dart`) extends `Core`, chooses the default module implementations, and mixes in the feature layer from `../dx/`.
- Keyset resolution in every API: an explicit `keyset` argument wins, then `keysets[using]`, then the default keyset; otherwise `KeysetStore` throws `KeysetException`.

## Keyset extension settings

`Keyset.settings` stores feature state under `#`-prefixed keys. Features expose them through extensions instead of adding fields to `Keyset`:

- `#token`: `PamKeysetExtension` (`../dx/pam/extensions/keyset.dart`).
- `#filterExpression`, `#heartbeatInterval`: `../subscribe/extensions/keyset.dart`.
- `#fileMessagePublishRetryLimit`: `../dx/files/extensions/keyset.dart`.

Add new per-keyset feature state the same way. Do not add fields to `Keyset` for one feature.

## Supervisor

- `Fiber` wraps one request. `Fiber.run` executes the action. On an `Exception` it asks `SupervisorModule.runDiagnostics` to classify it, then `runStrategies` for a list of `Resolution`s (`fail`, `delay`, `retry`, `networkStatus`). A Dart `Error` fails immediately.
- `NetworkingModule.register` installs the only diagnostics and strategy (`../networking/meta/`). The strategy retries **subscribe requests only**, following the configured `RetryPolicy`; every other request fails on its first error.
- `Signals` broadcasts `networkIsUp`, `networkIsDown`, and `networkIsConnected`. The subscribe loop restarts on `networkIsConnected`.

## Exceptions

- `exceptions.dart`: `PubNubException(message, [stackTrace])`, plus `KeysetException`, `MethodDisabledException`, `InvalidArgumentsException`, `UnknownException`, `MalformedResponseException`, `NotImplementedException`, `PublishException`, `MaximumRetriesException`, `ForbiddenException(service, reason)`, `DataSyncException`.
- Elsewhere: `ParserException` (`parser.dart`), `CryptoException` (`crypto/crypto.dart`), request exceptions (`net/exceptions.dart`), `InvariantException` (`../dx/_utils/ensure.dart`), `FileValidationException` (`../dx/_utils/file_validation.dart`).
- HTTP error bodies are mapped to these types in `../dx/_utils/exceptions.dart`.

## Logging

- Each file declares `final _logger = injectLogger('pubnub.<area>')`, which returns a `LazyLogger`. It resolves on use: the logger provided to the current `Zone` by `provideLogger`, then a matching entry in `globalLoggerRegistry` (set up by per-instance `LoggingConfiguration`), then a no-op `DummyLogger`.
- `Level` values are plain `int`s and are not ordered by verbosity: `fine` is 500 while `verbose` is 320. Compare against named levels; do not assume a numeric order.
- Log API parameters as `LogEvent(message:, details:, detailsType: LogEventDetailsType.apiParametersInfo)`.

## Invariants

- No platform imports (`dart:io`, `dart:html`, `dart:js_interop`) in this directory.
- Adding an abstract member to `INetworkingModule`, `IParserModule`, `ICryptoModule`, or `ICryptor` breaks consumers who implement them. Treat it as a breaking change.
- Adding a subclass to `PubNubException` is additive. Changing which exception an existing failure throws is a behavior change that must be noted in the PR.
- Use `Timetoken` for timetokens. It wraps `BigInt` to keep 17-digit values exact on the web.
