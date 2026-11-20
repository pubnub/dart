# Testing

Where tests live and how to match existing style. What to write for a given change is specified in the task; match nearby tests for the same feature.

## Layout

- **Unit tests** (`pubnub/test/unit`, preset `unit`): `package:test/test.dart` and `package:pubnub/pubnub.dart`. Networking is `FakeNetworkingModule` from `test/unit/net/fake_net.dart`. No live network.
- **Integration tests** (`pubnub/test/integration`, preset `integration`): tag `@Tags(['integration'])`. DataSync files also use `@TestOn('vm')`. Preset timeout for the `integration` tag is 1 minute (`pubnub/dart_test.yaml`).
- **Acceptance tests** (`acceptance_tests/`): Gherkin via `gherkin`, feature path `FEATURES_PATH` or `../../service-contract-mock/contract/features`, tag filter `not @skip and not @na=dart and not @beta`. CI starts a mock server first. Do not treat these as the default check for an SDK change.
- **Fixtures** next to a test are `part` files (`part './fixtures/publish.dart';`) or shared `_helpers.dart` / `_utils.dart` libraries.

`pubnub_flutter/test` uses `flutter test`. It is outside the current CI matrix (`pkg: [pubnub]` only).

## Fake networking

```dart
when(
  method: 'POST',
  path: '/v1/datasync/subkeys/test/entities?pnsdk=PubNub-Dart/${PubNub.version}&uuid=test',
  headers: {'Content-Type': ['application/vnd.pubnub.objects.entity+json;version=1']},
  body: '{"data":{...}}',
).then(status: 200, body: '{"data":{...}}');
```

`when` / `then` queue mocks. A mismatch throws `MockException` and prints method, URI, body, and headers. Comparison rules that matter:

- Path, scheme, host, and port must match. Query keys are compared as a set; order does not matter. Extra or missing keys fail.
- `defaultFlow` adds `uuid`. The origin adds `pnsdk=PubNub-Dart/${PubNub.version}`. Expected paths must include both unless the call does not go through that path.
- Headers are case-insensitive. Pass expected headers as `Map<String, List<String>>`. `absentHeaders` asserts a header was not sent (`If-Match` when `ifMatchesEtag` was omitted).
- JSON bodies compare structurally, ignoring object key order. Non-JSON bodies compare as strings.
- Status other than 200 or 204 raises `RequestFailureException` inside the fake handler, which is what `defaultFlow` turns into a `PubNubException`.

DataSync unit tests should use `test/unit/dx/datasync/_helpers.dart`: `newClient()`, `dsPath`, `contentType`, `dataBody`, `body`, `header`. `dsPath` already appends `pnsdk` and `uuid`. Do not hand-roll a second path helper.

Group names look like `group('DX [publish]', ...)` or `group('DataSync [entity] createEntity', ...)`. Assert exceptions with `throwsA(TypeMatcher<InvariantException>())` or `isA<DataSyncException>().having((e) => e.errorCode, 'errorCode', 'DS-0100')`.

## Live tests

Environment variables read by the tree:

| Tests | Variables | Fallback |
|---|---|---|
| Most integration tests | `SDK_SUB_KEY`, `SDK_PUB_KEY` | `demo` |
| PAM integration | `SDK_PAM_SUB_KEY`, `SDK_PAM_PUB_KEY`, `SDK_PAM_SEC_KEY` | `demo-36` |
| DataSync integration and `pam_token/_pam_client.dart` | `DS_PUBLISH_KEY`, `DS_SUBSCRIBE_KEY`, `DS_SECRET_KEY` | none (`subscribeKey` becomes `''`) |

DataSync live tests do not skip when those variables are unset. Without the keys they fail. Do not invent keys and do not add a skip unless the task asks. Prefer the fake-net unit test locally.

DataSync integration helpers (`test/integration/datasync/_helpers.dart`):

- `freshId(prefix)` — server rejects `_` in ids (`DS-0004`). Prefixes must not contain `_`.
- `superClient` / `testClient` / `readerClient` — secret-key admin client, per-test client plus `Cleanup`, token client.
- `Cleanup` runs removals in reverse and ignores failures.
- Seeded classes used by the suite: `DartCustomer`, `DartLoanQuote`, `DartREQUESTED_BY`, and the global User, Channel, and Membership classes.
- `throwsDataSync('DS-0100')` matches `DataSyncException.errorCode`.

## Commands

From `pubnub/`:

| Goal | Command |
|------|---------|
| Unit | `dart test -P unit` |
| One file | `dart test test/unit/dx/<file>_test.dart` |
| Integration | `dart test -P integration` |
| Both (CI `derry test default`) | `dart test -P unit && dart test -P integration` |
| Analyzer | `dart analyze --fatal-warnings lib` |
| Format | `dart format -o none --set-exit-if-changed lib` |

Format and analyze in CI cover `lib` only. Still match the surrounding test style. Apply `dart format` to tests you edit.

When verifying a change, run the narrowest file first, then the preset that contains it. Do not claim integration tests passed when the DataSync keys were absent.
