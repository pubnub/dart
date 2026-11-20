---
name: dart-pr-review
description: >-
  Review a pull request in the PubNub Dart SDK as a merge gate: blockers,
  other issues, and whether behavior changes have test coverage, using this
  repository's Dart conventions. Use when the user asks for a PR review,
  merge review, or Dart SDK review, or invokes this skill by name (for
  example "Use dart-pr-review") and specifies a PR link or the current
  branch. Prefer this skill over the generic pr-review skill in this
  repository.
---

# Dart PR review

You are responsible for keeping the PubNub Dart SDK safe to merge. If this PR had been added by your developer, would you merge it? If not, what are the blockers?

This skill is the Dart-specific version of `pr-review` for this repository. When both apply, follow this file.

Read-only. Do not edit files, commit, push, or post review comments unless the user asks.

`AGENTS.md` summarizes conventions. When it conflicts with current code, `pubnub/pubspec.yaml`, `pubnub/dart_test.yaml`, or CI, the repository wins. Language constraint is the `environment.sdk` in `pubnub/pubspec.yaml` (`>=3.2.0 <4.0.0`).

## Parameter

The invocation must specify one target:

- a PR link (GitHub pull request URL, or `owner/repo#number`)
- the current branch

If neither is specified, stop and ask which one. Do not guess.

## Get the diff

Review the changes that would merge. Read enough surrounding code, call sites, and tests to judge each change. Do not review from commit subjects alone.

**PR link**

- `gh pr view <url> --json title,body,baseRefName,headRefName,files,additions,deletions`
- `gh pr diff <url>`
- Read changed files when the diff is not enough to judge correctness or tests.

**Current branch**

- Base is the repo default branch (`origin/HEAD`, usually `main` or `master`) unless the user named another base.
- `git status`, `git log <base>..HEAD`, `git diff <base>...HEAD` (three-dot / merge-base).
- Include uncommitted changes and say that they are included. Ignore untracked agent or editor files unless the user asked to include them.
- If the branch has no unique commits and no relevant uncommitted changes, say so and stop.

## Read before judging

Read the matching doc when the diff touches that area. Do not judge an endpoint, error, test, DataSync, or subscribe change from memory of this file alone.

| Diff touches | Read |
|---|---|
| HTTP endpoints, request or result types, query, headers, platform networking | `.ai/knowledge/endpoints.md` |
| `Ensure`, exceptions, crypto errors | `.ai/knowledge/errors.md` |
| `pubnub/test/` or acceptance tests | `.ai/knowledge/testing.md` |
| DataSync entities, relationships, users, channels, memberships, events, or DataSync PAM | `.ai/knowledge/datasync.md` |
| Subscribe, projections, or subscription events | `.ai/knowledge/subscribe.md` |

## What to check

Judge safety of the repository: correctness, security, data loss, API breakage, races, error handling, and whether the change does what it claims.

List blockers and other issues.

Verify if changes that require tests have the test coverage. A change requires tests when it changes behavior, fixes a bug, or adds a path that can fail. Missing coverage for that change is a blocker when the new or changed behavior is unverified. If existing tests already cover it, say which ones. Do not require new tests for comments, formatting, renames, or generated files.

Ignore a missing version bump and a missing changelog update. CI owns those. Do not list them as blockers or other issues.

An unrequested edit is a blocker when it changes `version` in `pubnub/pubspec.yaml`, `Core.version` in `pubnub/lib/src/core/core.dart`, `pubnub/CHANGELOG.md`, or `.pubnub.yml`. The two version strings must stay identical. `pnsdk` and unit-test paths embed `Core.version`.

Flag an issue only when it was introduced by this change, is concrete, and the author would fix it. Skip speculative concerns, pre-existing problems, and style nits that do not obscure the code. `dart format` is the style source of truth. Do not flag `todo` comments. Do not ask for a linter migration.

### Dart SDK blockers

Treat these as blockers when the diff introduces them. Confirm each one against the peer it claims to follow.

**Public API**

- A type or member that callers of `package:pubnub/pubnub.dart` are expected to use is missing from a `show` list in `pubnub/lib/pubnub.dart`. `*Params` stay off that list. Implementation imports `package:pubnub/core.dart`.
- A public signature, result field, exception type, or event subtype changes in a way existing callers cannot absorb.
- A new `SubscriptionEvent` subtype is not handled in `SubscriptionEvent.fromEnvelope`, the `show` list, and exhaustive `switch`es on `events`.
- Code uses a Dart API outside `environment.sdk`.

**Endpoints and errors**

- Path, query name, content type, or status handling does not match the peer in the same feature, or was invented instead of taken from the task.
- Objects (App Context: `pubnub.objects`, `/v2/objects/...`) and DataSync (`pubnub.dataSync`, `/v1/datasync/subkeys/...`) share paths, types, or PAM scopes. `ResourceType.uuid` does not authorize a DataSync user. DataSync users and channels encode as `users` and `channels`; projections use a `datasync:` scope.
- Required arguments are not validated with `Ensure` before the request is built. Empty string (`isNotEmpty`) and null (`isNotNull`) are different checks. Missing keysets throw `KeysetException`, not `InvariantException`.
- Keyset resolution does not follow the peer: `keyset ??= keysets[using]` on a mixin, or `keyset ??= _core.keysets[using]` on a `*Dx` service.
- A call that peers send through `defaultFlow` builds and sends HTTP itself. Subscribe is the exception: `SubscribeLoop` calls `handler.response(SubscribeParams.toRequest())` and must not also be routed through `defaultFlow` while `SubscribeParams` still adds `uuid`, `auth`, and `signature`.
- An optional query is sent as `{}` where peers pass `null`, or an unset optional integer is sent as `0`.
- A networking or parser change updates only one of `stub.dart`, `io.dart`, and `web.dart` for a conditional export.
- A new exception type is thrown from an endpoint that already maps failures through `getExceptionFromAny`, unless the task asks for that type.
- Crypto failure text includes key material or plaintext.

**Tests**

- Behavior that needs a test has none. Unit tests use `FakeNetworkingModule` (`pubnub/test/unit/net/fake_net.dart`), keys `demo` / `test`, and no live network. Expected paths include `pnsdk=PubNub-Dart/${PubNub.version}` and `uuid` when the call goes through `defaultFlow` or the networking module.
- A DataSync unit test builds its own path or header helper instead of `pubnub/test/unit/dx/datasync/_helpers.dart` (`dsPath` already appends `pnsdk` and `uuid`).
- A test embeds a real key, or a DataSync integration test skips when `DS_PUBLISH_KEY`, `DS_SUBSCRIBE_KEY`, or `DS_SECRET_KEY` is unset. That suite fails closed. Do not treat acceptance tests as the default coverage for an SDK change.

**Scope**

- `pubnub_flutter` changes when the PR is not about Flutter widgets. That package is `publish_to: none` and is not in the CI matrix (`pkg: [pubnub]`).
- Unrelated edits to other endpoints, or a rename of the existing camelCase crypto files (`legacyCryptor.dart`, `aesCbcCryptor.dart`, `cryptoConfiguration.dart`, `cryptorHeader.dart`).

### Read-only CI checks

When `pubnub/lib` changed, run these from `pubnub/` if the Dart toolchain is available. They match CI (`derry validate analysis`, `derry validate formatting`). A failure is a blocker. Quote the diagnostic.

- `dart analyze --fatal-warnings lib`
- `dart format -o none --set-exit-if-changed lib`

Do not run integration tests; they need live keys. Do not run the full unit suite. When a specific failure is needed to confirm a blocker, run that one file: `dart test test/unit/<path>_test.dart` from `pubnub/`.

If the toolchain is missing, say so and judge analyzer and format issues from the diff.

## Output

Answer the merge question first.

```markdown
## Merge

Yes. / No.

<one or two sentences: why it is safe to merge, or what blocks it>

## Blockers

- `path/to/file:line` — what is wrong, in which scenario, and what must change before merge.

## Other issues

- `path/to/file:line` — non-blocking problem worth fixing.

## Tests

- What behavior changed and which tests cover it.
- Gaps that are blockers are repeated here with the test that is missing.
```

If a section has nothing, write `None.`

Order blockers by severity. Cite the smallest range that overlaps the diff. Name the CI command when a blocker is an analyzer or format failure.
