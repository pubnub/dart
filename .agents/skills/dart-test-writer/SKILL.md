---
name: dart-test-writer
description: Write, change, or review a unit or integration test (package:test) in the PubNub Dart SDK under pubnub/test/. Holds the repository's test code rules and the test-writing procedure.
---

# Dart test writer

Writes unit and integration tests for this repository. It assists the author; it does not replace review.

Scope: `pubnub/test/unit/` and `pubnub/test/integration/`. Run every command from `pubnub/`.

## Rules

Apply these rules to every new or changed test. Existing tests are migrated gradually; do not rewrite untouched tests to conform.

- Put tests in a file named `<subject>_test.dart` with a top-level `void main()`. Any other name is never discovered by the runner.
- Name groups in the existing `'<Area> [<feature>] <method or aspect>'` form, for example `'DX [publish]'` or `'DataSync [entity] createEntity'`. Describe each test in lowercase prose as `'<scenario> <expected outcome>'`, for example `'publish with empty channel throws InvariantException'`. The full name must be unique in the file.
- Structure each test as Arrange, Act, Assert, separated by blank lines.
- Verify one behavior per test. Several `expect` calls are fine when together they describe one outcome.
- Call the SDK exactly as a consumer would, through `PubNub` and the types exported from `package:pubnub/pubnub.dart`. Import `package:pubnub/core.dart` or `package:pubnub/src/...` only when the subject under test is internal, such as a `Params` class, `CryptorHeader`, or `projectionChannel`.
- Await every asynchronous expectation: `await expectLater(future, throwsA(...))`, `await expectLater(stream, emitsInOrder([...]))`. Do not leave an async matcher unawaited.
- When failure is expected, assert the exact exception type and the field that identifies the failure, for example `throwsA(isA<ForbiddenException>().having((e) => e.reason, 'reason', 'Forbidden'))` or `DataSyncException.errorCode`. `throwsException` or a bare `throwsA(anything)` is not enough.
- Write fixed expected values inline in the assertion. Do not compute expected values from a fixture or from the result under test.
- Do not use `Future.delayed`, `sleep`, or wall-clock comparisons in unit tests. Wait for an observable signal: an awaited future, `expectLater` with a stream matcher, `StreamQueue.next` with `.timeout(...)`, or a `Completer`. Integration tests have one narrow exception, described in their reference.
- Do not depend on test order or on state left by another test. `setUp` may build a fresh client for each test. Never keep mutable state in `setUpAll` or in top-level `var`s that tests change. Top-level `const` and `final` test data are allowed.
- Do not widen production visibility, add exports, or add test-only behavior to `lib/` to make a test possible.
- Do not add test dependencies. Use the existing doubles instead of `mockito` or `mocktail`.
- Name test doubles with one of two prefixes. `Fake` is a working lightweight implementation of a module interface, such as `FakeNetworkingModule`. `Mock` returns canned data or records calls, such as `MockCryptoModule` and `MockResponse`.
- Keep large response bodies in fixture files under `fixtures/`, declared `part of '../<subject>_test.dart';` and pulled in with `part './fixtures/<subject>.dart';`. Fixture values are library-private `const` or `final` strings.
- Platform annotations go first in the file, before imports. Use `@TestOn('vm')` for tests that need `dart:io`. Every integration file also carries `@Tags(['integration'])`.
- The new or changed test must add no analyzer errors or warnings and must be formatted with `dart format`.

## Choose the workflow

- For a unit test or unit-test review, read [references/unit-tests.md](references/unit-tests.md).
- For an integration test or integration-test review, read [references/integration-tests.md](references/integration-tests.md).

## Finish

1. Run the file: `dart test test/<path>_test.dart`. Add `--name '<description>'` to iterate on one test. Run the preset (`dart test -P unit`) when shared helpers or fixtures changed.
2. Run `dart analyze test/<path>_test.dart` and fix every error and warning in the lines you touched.
3. Run `dart format test/<path>_test.dart`.
4. Re-read the test against the Rules section and the selected reference, then fix every deviation.
