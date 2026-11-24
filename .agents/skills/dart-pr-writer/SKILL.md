---
name: dart-pr-writer
description: Write or change a PR title or PR description in the PubNub Dart SDK, and open the PR. Holds the repository's PR text rules, which the release bot parses into the changelog and the next pub.dev version.
---

# Dart PR writer

The release bot (`@pubnub-release-bot`, driven by `.github/workflows/commands-handler.yml`) builds `pubnub/CHANGELOG.md` and `.pubnub.yml`, and picks the next version from the PR body. Treat the body as machine input, not as free prose.

## Rules

- The title is free-form: no `type(scope):` prefix, about 60 characters, summarizing the net change against `master`.
- The description holds one entry per user-visible change, separated by blank lines, and nothing else. Do not add reviewer context, test notes, or checklists, and do not post any PR comment.
- Write each entry as `<type>(<scope>): <subject>`.
- `type` is exactly one of `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `style`, `test`. It picks the changelog section and the version bump: `feat` is minor, `fix` and `perf` are patch, the rest are not user-visible.
- `scope` is an optional short lowercase area name, such as `crypto`, `subscribe`, `datasync`, `pam`, `files`, `objects`, `presence`, `networking`, or `logging`. Omit the parentheses when none fits.
- Make the subject imperative and as short as the change allows; about 60 characters is a ceiling, not a target. Name public API as consumers write it, such as `pubnub.dataSync.updateUser`.
- Default to one line. Add a body after a blank line only for essential behavior or migration details. Use one or two plain-prose sentences, wrapped at 100 characters; no headings, bullets, or code blocks, as the bot joins lines.
- When the change breaks public API, end the entry with a body, a blank line, and `BREAKING CHANGES: <short description>`, whatever its type. Never choose a type to avoid it. Breaking changes in this package include:
  - removing or renaming an exported symbol, or narrowing a `show` list;
  - changing a public signature, default, or thrown exception type;
  - adding an abstract member to a public interface such as `INetworkingModule`, `ICryptoModule`, or `ICryptor`;
  - adding a subtype to the sealed `SubscriptionEvent` or `ObjectsEvent`;
  - raising the SDK lower bound in `pubspec.yaml`.
- Note any widened visibility or new export in the entry body, as `CODING_STANDARDS.md` requires.
- Add `Closes #N` only when the user asks.
- Do not edit release-managed files (see `AGENTS.md`) to describe the change; the bot does that from these entries.

## Opening the PR

1. Run `git diff master...HEAD` and write the title and entries from the net diff.
2. Run `gh label list`. If `type:` labels exist, apply one for the highest-priority entry: `feat`, `fix`, `perf`, then any other. Use `type: <type>`, mapping `feat` to `feature`, `docs` to `documentation`, `perf` to `performance`, and `ci` or `style` to `chore`. Apply only labels that exist.
3. Use `priority: none`, if that label exists, unless the user names another priority (`high`, `medium`, `low`).
4. Run `gh pr create --base master` with the title, description, and labels.
5. Run `gh pr view`, check that the title, body, and labels match your intent, and tell the user the title, the entries, any `BREAKING CHANGES:` footer, and any label you could not apply.

If `gh` cannot reach the repository, for example because of an organization IP allow list, stop. Give the user the title, the description, and the intended labels to apply themselves.

## Editing an existing PR

Rewrite the title or description from the net diff and apply it with `gh pr edit` without waiting for approval, since edits are reversible. Then do step 5.
