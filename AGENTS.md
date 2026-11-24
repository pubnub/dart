# AGENTS.md

This file provides guidance to AI coding tools working in this repository.

## Scope

This repository contains the official PubNub Dart SDK. The only package covered by this guidance is `pubnub/`, published to pub.dev as `pubnub`. Run every `dart` command from `pubnub/`.

Prefer guidance in this file over assumptions from source layout alone. If repository structure and this file disagree, update this file as part of the change.

## How to Work

- Follow the nearest peer in the same feature area before inventing structure. Feature methods take positional and named arguments and return a `Future` of a `Result`; there are no builders.
- Take paths, query names, content types, and status semantics from the task or from the peer. Never invent them.
- Keep changes scoped. Do not reformat or refactor unrelated endpoints.
- Integration tests read the environment variables listed under Testing.
- Objects (App Context: `pubnub.objects`, `v2/objects/...`) and DataSync (`pubnub.dataSync`, `v1/datasync/subkeys/...`) are different APIs, although both have users, channels, and memberships. Do not mix their paths, types, or PAM scopes. Tests named `app_context_*` cover Objects.

## Public Surface

- The primary public entry point is `PubNub` in `pubnub/lib/src/default.dart`.
- Client configuration is provided through `Keyset` (`pubnub/lib/src/core/keyset/keyset.dart`) and the optional modules passed to the `PubNub` constructor.
- Consumers import these libraries:
  - `package:pubnub/pubnub.dart`: the main library.
  - `package:pubnub/crypto.dart`, `package:pubnub/logging.dart`, `package:pubnub/networking.dart`: opt-in module libraries.
- `package:pubnub/core.dart` is the internal `@nodoc` barrel that `lib/src/` imports. It is not consumer API.
- A symbol is public API only when one of the consumer libraries above exports it, almost always with an explicit `show` list. Everything else under `lib/src/` is implementation, even when it is not `_`-private.

## Architecture

```text
PubNub (src/default.dart)
  ├─ feature mixins and façades ── src/dx/        publish, signal, presence, pam, push, files, objects, datasync, ...
  ├─ real-time subscribe ───────── src/subscribe/ Manager → SubscribeLoop → Subscription / SubscriptionEvent
  └─ Core (src/core/)              keysets + module contracts + supervisor + logging primitives
        ├─ INetworkingModule ──── src/networking/  dart:io (HTTP/1.1 + HTTP/2) or browser XHR (JS and WASM)
        ├─ IParserModule ──────── src/parser/      JSON/XML, BigInt-safe on web
        ├─ ICryptoModule ──────── src/crypto/      CryptoModule + cryptors, PNED header
        └─ SupervisorModule ───── src/core/supervisor/  Fiber, diagnostics, strategies, signals
```

Read the module guide before editing a module. These guides hold the architecture, invariants, and extension steps for their directory:

| Module | Guide |
| --- | --- |
| Core contracts, keysets, exceptions, supervisor, logging | `pubnub/lib/src/core/AGENTS.md` |
| Feature layer and the endpoint pattern | `pubnub/lib/src/dx/AGENTS.md` |
| DataSync | `pubnub/lib/src/dx/datasync/AGENTS.md` |
| Subscribe loop, subscriptions, events | `pubnub/lib/src/subscribe/AGENTS.md` |
| Crypto module and cryptors | `pubnub/lib/src/crypto/AGENTS.md` |
| Networking, platform-conditional code, HTTP/2 | `pubnub/lib/src/networking/AGENTS.md` |

## Coding Standards

Read and follow `CODING_STANDARDS.md` before writing or changing production Dart library code. It is the only place for production code quality and style rules. This file does not restate them.

## Dependencies and Platforms

- Dart SDK constraint: `>=3.2.0 <4.0.0` (`pubnub/pubspec.yaml`). Do not use language features or SDK APIs newer than the lower bound.
- The package runs on the Dart VM, on the web compiled with dart2js and dart2wasm, and inside Flutter apps. Platform-neutral code must compile on all of them; see `pubnub/lib/src/networking/AGENTS.md`.
- Do not add, remove, or widen production dependencies without the user's approval. Prefer the SDK and the existing dependencies.
- Test-only dependencies are `test` and `intl`. Do not add mocking or code-generation packages.
- `pubspec.lock` is gitignored, as is conventional for a library package.
- Lints come from `package:pedantic` through `pubnub/analysis_options.yaml`. Do not change the lint configuration unless the task is about it.

## Testing

To write, change, or review a unit or integration test, use the `dart-test-writer` skill (`.agents/skills/dart-test-writer/SKILL.md`). It is the only place for test code rules and the test-writing procedure.

`pubnub/dart_test.yaml` defines the `unit` and `integration` presets and the `integration` tag (timeout 1m).

### Unit Tests (`pubnub/test/unit/`)

- One `*_test.dart` file per feature, mirroring `lib/src/` areas (`core/`, `crypto/`, `dx/`, `logging/`, `net/`, `parser/`, `subscribe/`).
- No real network. `FakeNetworkingModule` in `test/unit/net/fake_net.dart` serves queued `when(...).then(...)` mocks.
- Fixtures are `part of` files under `fixtures/` next to the test that owns them.

### Integration Tests (`pubnub/test/integration/`)

- Make real requests to PubNub. Each file starts with `@TestOn('vm')` and `@Tags(['integration'])`; untagged files never run in the `integration` preset.
- Keys come from environment variables: `SDK_PUB_KEY`, `SDK_SUB_KEY`, `SDK_PAM_PUB_KEY`, `SDK_PAM_SUB_KEY`, `SDK_PAM_SEC_KEY`, `DS_PUBLISH_KEY`, `DS_SUBSCRIBE_KEY`, `DS_SECRET_KEY`. Never commit keys.
- The DataSync and PAM token suites have no fallback keys and fail, rather than skip, without the `DS_*` variables. Do not add skips, and never report them as passing when the keys were absent.
- `test/integration/web_compatibility_test.dart` is `@TestOn('browser')` and only runs when a browser platform is requested explicitly.

### Validation

Use the smallest relevant validation step first. CI (`.github/workflows/run-tests.yml`) runs the `scripts:` in `pubspec.yaml` through `derry`; the raw commands below are equivalent and do not need `derry` installed.

```bash
dart pub get
dart analyze --fatal-warnings lib                       # CI gate: derry validate analysis
dart format -o none --set-exit-if-changed lib           # CI gate: derry validate formatting
dart analyze test example                               # no errors; add no new warnings
dart test test/unit/dx/publish_test.dart                # one file; add --name '<description>' for one test
dart test -P unit                                       # derry test unit
dart test -P integration                                # derry test integration; needs the keys above; asks for permission
dart test -p chrome test/integration/web_compatibility_test.dart   # web- or WASM-sensitive changes; needs Chrome and network
dart pub publish --dry-run                              # pubspec, export, or package layout changes
```

- `test/` and `example/` carry pre-existing analyzer warnings and infos that CI does not gate. Do not add new ones, and do not mass-fix unrelated ones.
- Run the browser test when you change platform-conditional code, `package:web` / `dart:js_interop` usage, or number parsing.
- Do not run `build_runner`. The package has no `build.yaml` and no `build_runner` dependency (see Known Gaps).

### Before Completing a Task

1. Inspect the diff for unrelated changes, and revert them.
2. Run the narrowest relevant test file, then its preset when shared code changed.
3. Run the two CI gates when `pubnub/lib/` changed.
4. Report exactly which validation commands ran and whether they passed.
5. Never claim a test passed if it was not run. Say so when a suite was skipped for missing keys, a browser, or network access.

## Documentation Comments

To write, change, or review dartdoc comments on public API, use the `dart-doc-author` skill (`.agents/skills/dart-doc-author/SKILL.md`). It is the only place for dartdoc comment rules.

## Documentation Snippets

`pubnub/example/access_manager.dart` and `pubnub/example/datasync.dart` are snippet collections that documentation tooling extracts. The other files in `pubnub/example/` are runnable example programs; keep them runnable.

- Every region between `// snippet.<name>` and `// snippet.end` is pulled into the docs. Keep each marker alone on its line, keep each region self-contained, and preserve existing snippet names.
- Use only released public API imported from `package:pubnub/pubnub.dart`, and the shared top-level `demo` client declared at the top of the file. Follow the closest snippet in the same file.
- Each snippet is a top-level function. The file must compile as a whole: validate with `dart analyze example/<file>.dart`.
- Add snippets for new public API in the file for its area; create a new `example/<area>.dart` with the same header comment when none exists.

## Migration Guides

To draft or review a major-version migration guide, use the `dart-migration-guide-writer` skill (`.agents/skills/dart-migration-guide-writer/SKILL.md`). It is the only place for migration guide scope, evidence, and writing rules.

## Code Review

To review a PR or the current branch as a merge gate, use the `dart-pr-review` skill (`.agents/skills/dart-pr-review/SKILL.md`). Prefer it over generic code-review skills in this repository.

## Pull Requests

To write a PR title or PR description, or to open or edit a PR, use the `dart-pr-writer` skill (`.agents/skills/dart-pr-writer/SKILL.md`). It is the only place for PR text rules. Pull requests are squash-merged into `master`, so branch commit messages are free-form.

## Release-Managed Files

The release bot updates these files in the release commit. Never edit them by hand, including for version bumps:

- `.pubnub.yml`
- `pubnub/CHANGELOG.md`
- `version:` in `pubnub/pubspec.yaml`
- `Core.version` in `pubnub/lib/src/core/core.dart`
- The version reference in `pubnub/README.md`

`version:` in `pubspec.yaml` and `Core.version` must always be identical: the `pnsdk` query parameter and unit-test expectations embed `Core.version`.

## Editing Rules

- The repository has no license or copyright headers in source files. Do not add any.
- Dart files must be formatted with `dart format` and must not add analyzer diagnostics before a change is complete.
- Keep existing file names. Some `lib/src/crypto/` files are camelCase; do not rename them. New files are snake_case.
- Prefer updating tests when changing public behavior.
- Do not expose unreleased, internal, or not-yet-announced features in documentation, snippets, comments intended for users, or user-facing output.
- `pubnub/.pubignore` keeps the module guides out of the pub.dev archive. Add any other contributor-only file inside `pubnub/` to it, and confirm with `dart pub publish --dry-run`.
- If you change repository structure, test locations, presets, or validation commands, update this file and the affected module guide in the same change.

## Known Gaps

Repository facts that surprise agents. Remove an entry when it is fixed.

- `pubnub/test/unit/net/utils.dart` contains tests but never runs, because its name lacks the `_test.dart` suffix.
- `pubnub/test/integration/app_context/app_context_test.dart` has no `integration` tag, so the `integration` preset skips it.
- The `pubnub/doc/*.md` category pages are empty. `pubnub/dartdoc_options.yaml` references a missing `doc/DataSync.md`, which makes `dart doc` fail, and an `./examples` path prefix that does not exist.
- `dart pub publish --dry-run` reports one warning about the pre-release `form_data` dependency. Treat only new warnings as failures.
- The library comment in `pubnub/lib/networking.dart` mentions `package:dio`, which is not a dependency.
- `pubnub/README.md` tells contributors to run `build_runner`. That step is stale: there is no `build.yaml` and no `build_runner` dependency.

## Tooling

The harness supports Claude Code and Cursor. Both read this file and the nested module guides: Claude Code through the `CLAUDE.md` files that import them (`@AGENTS.md`), Cursor natively. Skills live in `.agents/skills/`, which Cursor discovers directly and Claude Code reaches through the `.claude/skills/` symlinks.

Hook scripts live in `.agents/hooks/` and are shared by both tools. Claude Code registers them in `.claude/settings.json`, Cursor in `.cursor/hooks.json`. The scripts detect Cursor through `CURSOR_VERSION`. They are silent on success, report only when the agent must act, and never block on their own failures (missing `dart` or `jq`, packages not fetched, timeouts). They need `bash` and `jq`, so they do not run on Windows without a POSIX shell.

- `run-dart-format-analyze.sh` (Claude Code `PostToolUse`, Cursor `afterFileEdit`): after every Dart edit under `pubnub/`, runs `dart format` on the file. In Claude Code it then runs `dart analyze` on the file and reports every diagnostic for `lib/` files, and only errors and warnings for `test/` and `example/` files. The edit is already applied; re-read the file after a reformat. In Cursor it only formats, because Cursor documents no way for that hook to reach the agent.
- `check-test-conventions.sh` (Claude Code `PostToolUse`; called by the Cursor stop hook): reports a test file the runner will never pick up: a missing `_test.dart` suffix, an integration test without the `integration` tag, or a unit test that carries it.
- `run-dart-analyze.sh` (Claude Code `Stop`, Cursor `stop`): when Dart files under `pubnub/lib/`, `pubnub/test/`, or `pubnub/example/` changed, runs the CI analysis and formatting gates on `lib/` and reports analyzer errors in `test/` and `example/` (for example, tests broken by a `lib/` API change). Claude Code receives the findings through exit code 2, Cursor as a follow-up message. It runs at most once per turn and does not run tests.
- `gate-shell.sh` (Cursor `beforeShellExecution`): denies `build_runner`, and asks before `dart test -P integration`, a bare `dart test`, a `test/integration` directory sweep, or `derry test` without `unit`. Unit runs and single test files are allowed.

Claude Code applies the same command guard through permissions in `.claude/settings.json`. Unit runs (`dart test -P unit`, `dart test test/unit/...`) are pre-approved, other `dart test` runs prompt, and `build_runner` is denied. `dart pub publish` and the bulk rewrite `dart fix --apply` are deliberately not pre-approved.
