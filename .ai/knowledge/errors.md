# Errors and validation

Behavior-changing rules for errors in this SDK. Inspect `lib/src/core/exceptions.dart`, `lib/src/dx/_utils/exceptions.dart`, and existing peers when implementing something new.

## Validation before the request

Use `Ensure` (`lib/src/dx/_utils/ensure.dart`). It throws `InvariantException`.

| Call | Message id | Text |
|---|---|---|
| `Ensure(value).isNotNull('channel')` | `not-null` | `channel cannot be null` |
| `Ensure(value).isNotEmpty('class name')` | `not-empty` | `class name cannot be empty` |
| `Ensure(value).isEqual(other, 'field')` | `is-equal` | `field has to equal <other>` |
| `Ensure.fail('not-together', 'name', ['pattern'])` | `not-together` | `name and pattern can not be provided together` |
| `Ensure.fail('invalid-type', ...)` | `invalid-type` | `<that> must be either <a> or <b>.` |

`isNotEmpty` accepts only a non-empty `String` or `List`. A `Map`, even a non-empty one, fails it. `buildJsonPatch` results are lists, which is why update methods check the operation list with `isNotEmpty`.

Message text is built from `_invariantMessages`. Do not change those templates casually. Add a new id next to the existing ones when a new wording is required.

Missing keysets throw `KeysetException` from `KeysetStore`, not `InvariantException`. `publish` also checks `publishKey` with `Ensure(...).isNotNull('publishKey')`.

## Server and transport failures

`defaultFlow` catches `RequestFailureException` (non-success HTTP status) and maps the body with `getExceptionFromAny`:

- `DefaultResult` whose `status == 400` and `message == 'Invalid Arguments'` becomes `InvalidArgumentsException` (fixed text, no constructor argument).
- `status == 403` and a history-delete message becomes `MethodDisabledException`.
- `status == 403` and message `Forbidden`, `Token is expired.`, or `Token is revoked.` becomes `ForbiddenException(service, reason)`.
- A `DefaultResult` with a non-empty `otherKeys['errors']` list becomes `DataSyncException.fromErrors`. DataSync error bodies are `{"errors":[{"errorCode","message","path"}]}`. `DefaultResult.fromJson` keeps unknown keys, including `errors`.
- A 3-element JSON list becomes `PublishException` using element `[1]`. Publish can also return HTTP 200 with `isError: true` on `PublishResult`; that path does not throw. Follow the peer.
- An `XmlDocument` (file service) becomes `PubNubException('Request failed. Details: ...')`.
- Anything else becomes `PubNubException('unknown exception (status N): ...')` or `PubNubException('<status> error: <message>')`.

Do not throw a new exception type from an endpoint that already flows through this mapper unless the task asks for one. Parse failures inside the mapper fall back to the raw body text.

`DataSyncException.errorCode` is the stable branch (`DS-0100`, and so on). `errorMessage` is not stable. Missing codes use `DataSyncException.unknownErrorCode` (`'unknown'`). `errors` always starts with this exception, then any further server errors. `MalformedResponseException` is for a success body whose required fields have the wrong shape (`_required` in DataSync `schema.dart`), not for HTTP errors.

Subscribe does not use `getExceptionFromAny`. Its loop has its own catch path in `subscribe_loop.dart`. A DataSync or Objects payload that cannot be parsed becomes `null` from `SubscriptionEvent.fromEnvelope` and is discarded, not thrown.

## Transport exceptions

Declared in `lib/src/core/net/exceptions.dart`: `RequestTimeoutException`, `RequestCancelException`, `RequestOtherException`, `RequestFailureException`. The supervisor may retry the fiber; an `Error` (as opposed to `Exception`) completes the fiber immediately and is not retried.

## Crypto

`Keyset.cipherKey` is deprecated and selects the legacy cryptor. New code configures `CryptoModule.aesCbcCryptoModule` on `PubNub`. Both `CryptoModule.aesCbcCryptoModule` and `CryptoModule.legacyCryptoModule` also decrypt AES-256-GCM (`ACGM`) payloads. Encryption stays on the factory's cryptor. AES-GCM decryption failures use the opaque `decryption error` message. Encryption failures surface as `PubNubException`. Do not widen cryptor exception messages with key material or plaintext.
