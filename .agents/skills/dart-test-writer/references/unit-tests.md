# Unit tests

Use this reference for tests in `pubnub/test/unit/`. The shared rules in `SKILL.md` remain authoritative.

## Start from observable behavior

Identify what the subject exposes:

- A returned value or thrown exception.
- Validation of input (`Ensure` → `InvariantException`, keyset resolution → `KeysetException`).
- A constructed HTTP request: method, path, query, headers, body.
- A decoded response, or an HTTP error mapped to a `PubNubException` subtype.
- An event decoded from a subscribe envelope.
- Encrypted or decrypted bytes.

Test the observable result, not private steps. List the cases before writing code: the success path, every new failure path, and each relevant boundary (empty, `null`, minimum, maximum, a 17-digit timetoken). Write one test per case.

## Choose the test shape

| Subject | Exercise | Assert |
| --- | --- | --- |
| Value or transformation | Call the function | Exact returned value |
| Argument validation | Call the public method with invalid input | `throwsA(isA<InvariantException>())` |
| Request construction | Queue a `when(...)` mock with the exact expected request, then call the API | The call completes. A mismatch throws `MockException` with an EXPECTED/ACTUAL diff. |
| Response decoding | Queue a mock with a fixture body | Exact fields of the `Result` |
| Error mapping | Queue a mock with an error `status` and body | Exact exception type and identifying field |
| Subscribe event decoding | `SubscriptionEvent.fromEnvelope` on a wire fixture | Event subtype and exact fields |
| Crypto | Known-answer vectors, then round trips | Exact bytes, with `reason:` per vector |

## Fake networking (`test/unit/net/fake_net.dart`)

- Create the client with `networking: FakeNetworkingModule()`. Its constructor clears the global mock queue, so build a fresh client in `setUp` or in the test itself.
- `when(method:, path:, headers:, body:, absentHeaders:)` describes one expected request. `.then(status:, body:, headers:)` describes its response. Mocks are consumed in FIFO order, one per request, so queue them in call order.
- The fake compares the method, the scheme, host, port, and path, and the query keys as a set: order is ignored, but an extra or missing key fails the match. JSON bodies are compared structurally (key order ignored); non-JSON bodies are compared as strings. Headers are compared case-insensitively and are passed as `Map<String, List<String>>`.
- `absentHeaders` asserts that a header is not sent, for example `absentHeaders: {'If-Match'}` when `ifMatchesEtag` was omitted.
- A status other than 200 or 204 makes the fake throw `RequestFailureException`, which exercises the SDK's real error mapping.
- A request with no mock queued fails with `MockException('set up the mock first')`.
- Put `uuid` in the expected path for every call that goes through `defaultFlow`, which adds it. `pnsdk` is optional: the fake applies its origin, which carries `pnsdk`, to both the expected and the actual URI (`test/unit/net/fake_net.dart`). Follow the nearest test in the file for whether to spell it out. DataSync's `dsPath` already includes both; do not hand-roll a second path helper.
- For requests to external URLs, such as Files uploads, use `EnhancedFakeNetworkingModule` and `whenExternal(...)` from `test/unit/net/custom_fake_net.dart`.
- To match encrypted payloads exactly, use `MockCryptoModule` (`test/unit/dx/utils/mock_crypto_module.dart`), which returns fixed ciphertext.

```dart
test('publish with valid channel and message returns sent result', () async {
  var pubnub = PubNub(
    defaultKeyset: Keyset(
        subscribeKey: 'demo', publishKey: 'demo', userId: UserId('test')),
    networking: FakeNetworkingModule(),
  );
  when(method: 'GET', path: '/publish/demo/demo/0/test/0/42?uuid=test')
      .then(status: 200, body: _publishSuccessResponse);

  var result = await pubnub.publish('test', 42);

  expect(result.isError, isFalse);
  expect(result.description, equals('Sent'));
  expect(result.timetoken, equals(1));
});
```

### Error mapping

```dart
test('listChannels with 403 response throws ForbiddenException', () async {
  when(method: 'GET', path: _listChannelsPath)
      .then(status: 403, body: _forbiddenErrorResponse);

  await expectLater(
    pubnub.channelGroups.listChannels('cg1'),
    throwsA(isA<ForbiddenException>()),
  );
});
```

Two classes are named `InvalidArgumentsException`. The REST error mapping throws the one from `core.dart`; file validation throws the one from `lib/src/dx/_utils/file_validation.dart`. Import the one the code path under test throws.

## Subscribe events

Decode the raw envelopes in `test/unit/subscribe/fixtures/wire_events.dart` through the local `_event(...)` helper in `subscription_events_test.dart`. Assert the subtype with `isA<…>()`, then every field the event exposes. Compare timetokens as `Timetoken(BigInt.parse('17905741246383965'))`, never as `int`. Add new wire shapes to the fixture file, copied from real service output.

## Crypto

Follow `test/unit/crypto/aes_gcm_cryptor_test.dart`. Use a table of `_Vector`s (name, cipher key, plaintext, payload hex), loop over them, and pass `reason: vector.name` to every `expect`. Then add separate tests for the round trip, the wrong key, truncated input, and a malformed `PNED` header. The last three expect `throwsA(isA<CryptoException>())`.

## DataSync

Use `test/unit/dx/datasync/_helpers.dart`:

- `newClient({authKey})` creates the client.
- `dsPath(resource, {id, query, subscribeKey, uuid})` builds paths.
- `contentType(type, {ifMatch})` and `header(name, value)` build headers.
- `body(value)` and `dataBody(data)` build request bodies.
- `customerPayload`, `userPayload`, `channelPayload`, `entityObject`, `userObject`, `channelObject`, `relationshipObject`, `membershipObject`, `notFoundError`, and `listBody` build payloads and responses.

Assert `DataSyncException.errorCode` for failures.

## Repository integration

- Place the test next to its peers: `test/unit/dx/<feature>_test.dart` for API features, and `test/unit/<module>/` for `core`, `crypto`, `logging`, `net`, `parser`, and `subscribe`.
- Reuse `test/unit/net/`, `test/unit/dx/utils/`, and the feature `_helpers.dart` before adding helpers. Name a new helper file with a leading underscore (`_helpers.dart`) and no `_test` suffix.
- Unit tests carry no `@Tags`. Add `@TestOn('vm')` only when the test imports `dart:io`.
- Validate with `dart test test/unit/<path>_test.dart`, then `dart test -P unit` when shared helpers changed.
