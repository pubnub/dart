---
name: dart-pr-review
description: Review a pull request or the current branch of the PubNub Dart SDK as a merge gate, reporting blockers, other issues, and whether changed behavior has test coverage, against this repository's Dart conventions. Use when the user asks for a PR review, merge review, or Dart SDK review, and prefer it over generic code-review skills in this repository.
---

# Dart PR review

You keep the PubNub Dart SDK safe to merge. Answer one question: if a teammate opened this PR, would you merge it? If not, what blocks it?

This skill is read-only. Do not edit files, commit, push, or post review comments unless the user asks.

`AGENTS.md` and the module guides summarize conventions. When they conflict with the current code, `pubnub/pubspec.yaml`, `pubnub/dart_test.yaml`, or CI, the repository wins; mention the stale guide as an other issue.

## Target

The request must name one target:

- a PR link (GitHub URL or `owner/repo#number`), or
- the current branch.

If neither is named, ask which one. Do not guess.

## Get the diff

Review what would merge. Read enough surrounding code, call sites, and tests to judge each change. Do not review from commit subjects alone.

- **PR link:** `gh pr view <pr> --json title,body,baseRefName,headRefName,files` and `gh pr diff <pr>`. If `gh` cannot reach the repository (for example, because of an organization IP allow list), say so and offer to review the branch locally instead.
- **Current branch:** the base is `master` unless the user names another. Run `git status`, `git log master..HEAD`, and `git diff master...HEAD`. Include uncommitted changes and say that they are included. If the branch has no unique commits and no relevant uncommitted changes, say so and stop.

## Read before judging

Read the guide for every area the diff touches. Do not judge from memory of this file alone.

| Diff touches | Read |
| --- | --- |
| Any change | `AGENTS.md`, and `CODING_STANDARDS.md` for `pubnub/lib/` |
| Endpoints, request or result types, query, headers, error mapping, `Ensure` | `pubnub/lib/src/dx/AGENTS.md` |
| DataSync, including events and DataSync PAM | `pubnub/lib/src/dx/datasync/AGENTS.md` |
| Subscribe, projections, subscription events | `pubnub/lib/src/subscribe/AGENTS.md` |
| Keysets, exceptions, supervisor, logging | `pubnub/lib/src/core/AGENTS.md` |
| Crypto | `pubnub/lib/src/crypto/AGENTS.md` |
| Networking, parser, platform-conditional code | `pubnub/lib/src/networking/AGENTS.md` |
| `pubnub/test/` | the `dart-test-writer` skill and its references |
| Public dartdoc | the `dart-doc-author` skill |

## What to check

Judge correctness, security, data loss, API breakage, races, error handling, and whether the change does what it claims.

Flag an issue only when this change introduced it, it is concrete, and the author would fix it. Skip speculative concerns, pre-existing problems, and style nits; `dart format` decides style. Do not flag `todo` comments, and do not ask for a lint migration.

A change needs tests when it changes behavior, fixes a bug, or adds a path that can fail. Missing coverage for such a change is a blocker. If existing tests already cover it, name them. Do not require tests for comments, formatting, or renames.

Ignore a missing version bump or changelog entry; the release bot owns those.

### Blockers

Treat these as blockers when the diff introduces them. Confirm each one against the peer it claims to follow.

**Public API**

- A type or member that consumers are meant to use is missing from the `show` list of the consumer library that should export it (`lib/pubnub.dart`, `crypto.dart`, `logging.dart`, `networking.dart`). `*Params` and other internals are exported, or are not marked `/// @nodoc` when public.
- A public signature, default, result field, thrown exception type, or event subtype changes in a way existing callers cannot absorb, and the PR text has no `BREAKING CHANGES:` entry (see `dart-pr-writer`).
- A new `SubscriptionEvent` or `ObjectsEvent` subtype is not handled in `SubscriptionEvent.fromEnvelope`, the `show` list, and every exhaustive `switch` in the package, examples, and tests.
- An abstract member is added to `INetworkingModule`, `IParserModule`, `ICryptoModule`, `ICryptor`, or `ILogger`.
- Code uses a language feature or SDK API newer than the `environment: sdk` lower bound in `pubnub/pubspec.yaml`.

**Endpoints and errors**

- A path, query name, content type, or status handling does not match the peer in the same feature, or was invented rather than taken from the task.
- Objects (App Context: `pubnub.objects`, `v2/objects/...`) and DataSync (`pubnub.dataSync`, `v1/datasync/subkeys/...`) share paths, types, or PAM scopes. `ResourceType.uuid` does not authorize a DataSync user.
- Required arguments are not validated with `Ensure` before the request is built, or `isNotEmpty` and `isNotNull` are confused. Keyset resolution differs from the peer (`keyset ??= keysets[using]` on a mixin, `keyset ??= _core.keysets[using]` on a façade).
- A call that peers send through `defaultFlow` sends HTTP itself, or subscribe is routed through `defaultFlow` while `SubscribeParams` still adds `uuid`, `auth`, and the signature.
- An optional query is sent as `{}` where peers pass `null`, or an unset optional integer is sent as `0`.
- A conditional export changes only one of its `stub.dart`, `io.dart`, and `web.dart` variants, or platform-neutral code imports `dart:io`, `dart:html`, `dart:js_interop`, or `package:web`.
- A new exception type is thrown from an endpoint that already maps failures through `getExceptionFromAny`, unless the task asks for it.
- An error message, log line, or exception includes a secret key, cipher key, auth key, token, signature, or decrypted payload. AES-GCM encryption is exposed or documented.

**Tests**

- Changed behavior has no test. Unit tests must use `FakeNetworkingModule` and `demo` / `test` keys, with no live network, and their expected paths must include `uuid` for calls that go through `defaultFlow`.
- A DataSync unit test builds its own path or header helper instead of using `test/unit/dx/datasync/_helpers.dart`.
- A test file that will never run: the name lacks `_test.dart`, an integration file lacks `@Tags(['integration'])`, or a unit test is tagged `integration`.
- A test embeds a real key, or a DataSync or PAM token integration test was changed to skip when the `DS_*` keys are unset.

**Scope**

- Unrequested edits to release-managed files: `.pubnub.yml`, `pubnub/CHANGELOG.md`, `version:` in `pubnub/pubspec.yaml`, or `Core.version` in `pubnub/lib/src/core/core.dart`. The two version strings must stay identical.
- Unrelated edits to other endpoints, or a rename of the existing camelCase crypto files.
- New production dependencies without the user's approval, or a change to the lint configuration.

### CI checks

When `pubnub/lib/` changed, run these from `pubnub/` if the Dart toolchain is available. They are the CI gates, so a failure is a blocker; quote the diagnostic.

- `dart analyze --fatal-warnings lib`
- `dart format -o none --set-exit-if-changed lib`

Do not run integration tests, which need live keys, or the full unit suite. To confirm a specific blocker, run one file: `dart test test/unit/<path>_test.dart`.

If the toolchain is missing, say so and judge analyzer and format issues from the diff.

## Output

Answer the merge question first.

```markdown
## Merge

Yes. / No.

<One or two sentences: why it is safe to merge, or what blocks it.>

## Blockers

- `path/to/file:line`: what is wrong, in which scenario, and what must change before merge.

## Other issues

- `path/to/file:line`: a non-blocking problem worth fixing.

## Tests

- Which behavior changed and which tests cover it.
- Missing tests that are blockers, repeated here with the test that is needed.

## Checks run

- The commands run and their results, or why they were not run.
```

Write `None.` for an empty section. Order blockers by severity, and cite the smallest line range that overlaps the diff.
