# AGENTS.md — PubNub Dart SDK

This file summarizes repository conventions for agents. It is **not** a substitute for checking the current code, `pubnub/pubspec.yaml`, `pubnub/dart_test.yaml`, and CI configuration. When this file conflicts with executable configuration or current code, treat the repository as authoritative and update this documentation if appropriate.

Feature-specific choices (file naming, public entry points, naming of delete/remove APIs, test scope) are defined in the task request — follow that, not this file.

## How to work in this repository

- Prefer existing peers in the same feature area over inventing structure. This SDK does not use Go-style builders. A feature method takes positional and named arguments and returns `Future<Result>`.
- Follow task/API specifications over assumptions. Do not invent paths, query names, content types, or status semantics.
- Keep changes scoped. Do not reformat or refactor unrelated endpoints.
- Do not bump `version` in `pubnub/pubspec.yaml` or `Core.version` in `pubnub/lib/src/core/core.dart`, and do not rewrite `pubnub/CHANGELOG.md` or `.pubnub.yml`, unless explicitly asked. Those two version strings must stay identical; `pnsdk` and unit-test paths embed `Core.version`.
- Never invent credentials. Unit tests use `demo` / `test` keys and `FakeNetworkingModule`. Live tests read environment variables already used in the tree.
- `pubnub/README.md` tells contributors to run `build_runner`. There is no `build.yaml` and `build_runner` is not a dependency. Do not run it.
- `pubnub_flutter` is an unpublished widget package (`publish_to: none`) and is not the SDK under test in CI. Change it only when the task is about Flutter widgets.

## Repository map

Dart SDK constraint is `>=3.2.0 <4.0.0` (`pubnub/pubspec.yaml`). CI is `.github/workflows/run-tests.yml` and `run-validations.yml`.

- `pubnub/` — published SDK (`package:pubnub/pubnub.dart`)
- `pubnub/lib/src/default.dart` — `PubNub` client
- `pubnub/lib/src/core/` — keysets, `Request` / `Result`, exceptions, retry, supervisor, parser interface
- `pubnub/lib/src/dx/` — feature APIs. Public entry points live next to `_endpoints/` request types
- `pubnub/lib/src/dx/_utils/` — `defaultFlow`, `Ensure`, exception mapping, PAM v2 signature
- `pubnub/lib/src/subscribe/` — multiplexed subscribe loop and typed event streams
- `pubnub/lib/src/networking/` — HTTP, with `stub` / `io` / `web` conditional exports
- `pubnub/lib/src/crypto/` — `CryptoModule`, AES-CBC, legacy cryptor, AES-256-GCM decryption (`ACGM`)
- `pubnub/test/unit/` — fake-net tests. `test/unit/net/fake_net.dart` is the interceptor
- `pubnub/test/integration/` — live tests
- `pubnub/example/` — runnable examples, not CI tests
- `acceptance_tests/` — Gherkin contract tests. They need the mock server and `FEATURES_PATH`
- `pubnub_flutter/` — Flutter widgets on top of `pubnub`

Public import is `package:pubnub/pubnub.dart`. Implementation imports `package:pubnub/core.dart` (`@nodoc`). A new public type is invisible until it is added to a `show` list in `pubnub/lib/pubnub.dart`.

## Important conventions

- Resolve the keyset the way peers do: `keyset ??= keysets[using]` on a mixin, or `keyset ??= _core.keysets[using]` on a `*Dx` service. `KeysetStore.[]` returns the default keyset when the name is null and throws `KeysetException` when it is missing.
- Validate with `Ensure` before building the request. Empty string and null are different checks (`isNotEmpty` / `isNotNull`).
- Log with `injectLogger('pubnub.dx.<feature>')` and a `LogEvent` (`detailsType: LogEventDetailsType.apiParametersInfo`) before `defaultFlow`.
- `*Params` extends `Parameters` and implements `toRequest()`. `*Result` extends `Result`, uses a private constructor, a `fromJson` factory, private fields, and public getters.
- Request URIs are relative `Uri(pathSegments: ...)`. The networking module applies the origin (`ps.pndsn.com` by default) and `pnsdk=PubNub-Dart/<version>`.
- Most calls go through `defaultFlow`. Subscribe does not: `SubscribeLoop` calls `handler.response(SubscribeParams.toRequest())` itself.
- New files use `snake_case`. Do not rename existing camelCase crypto files (`legacyCryptor.dart`, `aesCbcCryptor.dart`, `cryptoConfiguration.dart`, `cryptorHeader.dart`).
- Public dartdoc follows nearby methods, including `/// {@category ...}`. Repeat the keyset-resolution paragraph and projection rules with `{@template}` / `{@macro}` instead of copying a new wording.
- Mark types that must not appear in generated public docs with `/// @nodoc`.
- Prefer `UserId` on `Keyset`. The `uuid:` constructor parameter and `Keyset.cipherKey` are deprecated. New encryption uses `PubNub(crypto: CryptoModule.aesCbcCryptoModule(...))`.
- Objects (App Context) and DataSync are different APIs. Do not mix their paths, types, or PAM scopes. See [`.ai/knowledge/datasync.md`](.ai/knowledge/datasync.md).

Feature entry points:

| Surface | Where it lives |
|---|---|
| Methods on `PubNub` | mixins: publish, subscribe, signal, presence, PAM, push, message actions, time, supervisor |
| Grouped services | `pubnub.batch`, `channelGroups`, `objects`, `files`, `dataSync` |
| Single-channel handle | `pubnub.channel(name)` |
| DataSync realtime handles | `pubnub.dataSyncUser` / `dataSyncChannel` / `dataSyncEntity` |

## Validation

Run commands from `pubnub/` unless the task is in another package. Start with the narrowest relevant test, then broaden when the scope warrants it.

| Goal | Command |
|------|---------|
| Analyzer (CI) | `dart analyze --fatal-warnings lib` |
| Format check (CI, `lib` only) | `dart format -o none --set-exit-if-changed lib` |
| Unit tests | `dart test -P unit` |
| One file | `dart test test/unit/dx/datasync/entity_test.dart` |
| Integration | `dart test -P integration` |
| CI shape | `derry validate analysis`, `derry validate formatting`, `derry test default` |

`derry` scripts are declared under `scripts:` in `pubnub/pubspec.yaml`. CI activates `derry 1.5.0`. The same commands work without `derry`.

Analyzer config is `pubnub/analysis_options.yaml` (`package:pedantic/analysis_options.yaml`, `todo` ignored). Do not migrate the linter unless asked. `dart format` is the style source of truth (single quotes, trailing commas).

## Before completing a coding task

1. Inspect the diff for unrelated changes.
2. Run the narrowest relevant tests.
3. Run analyzer and format check when `lib/` changed.
4. Report which validation commands were run and whether they passed.
5. Do not claim tests passed if they were not executed.

## Detailed repository knowledge

When modifying HTTP endpoints, read [`.ai/knowledge/endpoints.md`](.ai/knowledge/endpoints.md).

When changing errors or validation, read [`.ai/knowledge/errors.md`](.ai/knowledge/errors.md).

When adding or modifying tests, read [`.ai/knowledge/testing.md`](.ai/knowledge/testing.md).

When changing DataSync (entities, relationships, users, channels, memberships, events, or DataSync PAM), read [`.ai/knowledge/datasync.md`](.ai/knowledge/datasync.md).

When changing subscribe, projections, or subscription events, read [`.ai/knowledge/subscribe.md`](.ai/knowledge/subscribe.md).

Other in-repo docs: root `README.md` and `pubnub/README.md` (consumers; the `build_runner` step there is stale), `.pubnub.yml` (product metadata; release pipeline owns changelog/version alignment).
