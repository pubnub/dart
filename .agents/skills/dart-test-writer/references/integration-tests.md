# Integration tests

Use this reference for tests in `pubnub/test/integration/`. The shared rules in `SKILL.md` remain authoritative.

## File header

Every integration test file starts with both annotations, before any import:

```dart
@TestOn('vm')
@Tags(['integration'])

import 'dart:io';

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';
```

The `integration` preset in `dart_test.yaml` uses `include_tags: integration`, so an untagged file never runs there. The only browser test is `web_compatibility_test.dart` (`@TestOn('browser')`). Keep browser checks in that file.

## Test through the public SDK

Integration tests make real PubNub requests. Create a real `PubNub` client with no injected networking, and exercise the public API as a consumer would. Do not use `FakeNetworkingModule` or unit-test fixtures.

Define the externally observable service behavior before writing the test. Keep setup operations, the behavior under test, and cleanup distinct. Assert every operation whose outcome the test depends on.

## Credentials

Read keys from the environment exactly as the helper for that keyset does:

| Keyset | Variables | Fallback when unset | Helper |
| --- | --- | --- | --- |
| Standard | `SDK_PUB_KEY`, `SDK_SUB_KEY` | `demo` | `test/integration/subscribe/subscribe_test.dart` |
| Access Manager (message actions) | `SDK_PAM_PUB_KEY`, `SDK_PAM_SUB_KEY`, `SDK_PAM_SEC_KEY` | `demo-36` | `test/integration/message_action/_utils.dart` |
| DataSync, and the PAM token tests | `DS_PUBLISH_KEY`, `DS_SUBSCRIBE_KEY`, `DS_SECRET_KEY` | **none** (the subscribe key becomes `''`) | `test/integration/datasync/_helpers.dart` (`superClient`, `testClient`, `readerClient`), `test/integration/pam_token/_pam_client.dart` |

The DataSync and PAM token suites fail closed: without the `DS_*` keys they fail, they do not skip. Do not add a skip, and do not invent keys. Without the keys, prefer the fake-network unit test locally, and report that the integration tests were not run.

Never commit real keys or tokens. The DataSync keyset must already provide the classes declared at the top of `datasync/_helpers.dart` (`DartCustomer`, `DartLoanQuote`, `DartREQUESTED_BY`, and the global classes).

## Isolate remote state

- Generate unique channel, group, user, and object identifiers for each test. In DataSync tests use `freshId(prefix)`; the prefix must not contain `_` (DS-0004). Use `runMarker()` to tag the objects one test creates. Elsewhere follow the helper in the same directory, such as `generateTestId()` in `app_context/_utils.dart`.
- Do not rely on execution order or on resources created by another test.
- Register cleanup as soon as a resource exists. In DataSync tests, `testClient()` returns `(pubnub, cleanup)`, registers `cleanup.run()` and `unsubscribeAll()` with `addTearDown`, and runs removals in reverse. Call `cleanup.add(() => ...)` right after each create. Elsewhere use `addTearDown` or `tearDown` to remove what the test created, then `await pubnub.unsubscribeAll()`.
- Cleanup may swallow "already removed" errors. The behavior under test must not.

```dart
test('setUser with a stale eTag throws DataSyncException DS-0300', () async {
  var (pubnub, cleanup) = testClient();
  var id = freshId('dartuser');
  await createUser(pubnub, cleanup, id); // creates and registers removal

  var update = pubnub.dataSync.setUser(
      id, UserUpdate(classVersion: classVersion),
      ifMatchesEtag: 'stale');

  await expectLater(update, throwsDataSync('DS-0300'));
});
```

The `create*` helpers (`createUser`, `createCustomer`, `createRequestedBy`, …) in `datasync/_helpers.dart` create an object and register its removal in one call. `throwsDataSync(errorCode)` asserts the exact `DataSyncException.errorCode`. Prefer both over hand-written equivalents.

## Events and subscriptions

The SDK has no connection-status stream, so follow the pattern in `test/integration/datasync/events_*_test.dart`:

1. Create the subscription and call `subscribe()`.
2. Start listening for the expected event first, for example `var event = sub.dataSync.firstWhere(...)` or a `StreamQueue`, so that an early event is not lost.
3. `await subscription.whenStarts`. If the loop is already running, this completes with its next request.
4. Wait a short, named settle `Duration` (the existing tests use `_settle = Duration(seconds: 3)`) so the service registers the subscription. This is the only accepted fixed delay, because nothing observable signals it. Never use a delay to wait for an event or a response.
5. Perform the action, then `await event.timeout(eventTimeout)`.
6. In `finally`, call `.ignore()` on pending futures and `await sub.cancel()`.

Use separate futures for each event the test verifies. Use ordered assertions only when order is part of the behavior.

## Timeouts

- The `integration` tag has a 1-minute default timeout (`dart_test.yaml`).
- Put timeouts on waits rather than on the test: `eventTimeout` (20 s, DataSync), `queue.next.timeout(...)`, `future.timeout(...)`.
- Long suites may set `timeout: Timeout(testTimeout)` on the group, as `message_action/_utils.dart` does.

## Repository integration

- Place the test in the feature directory under `test/integration/`. Reuse its `_helpers.dart`, `_utils.dart`, or `_pam_client.dart` before adding helpers.
- Run integration tests only when valid keys are in the environment: `dart test -P integration`, or `dart test test/integration/<path>_test.dart`. Without keys, report that the test was not run; do not treat the run as passing.
