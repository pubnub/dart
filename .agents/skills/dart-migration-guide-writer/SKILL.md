---
name: dart-migration-guide-writer
description: Draft or review a major-version migration guide for the PubNub Dart SDK (package pubnub). Use for pubnub/doc/migration/PubNub_<major>_0_Migration_Guide.md; not for release notes, changelogs, or minor releases.
---

# Dart migration guide writer

Create a complete migration guide that tells SDK consumers what they must change when moving from the latest release of the previous major version.

## Workflow

1. Read the repository's `AGENTS.md` and [the migration guide conventions](references/migration-guide-conventions.md).
2. Establish the comparison before inspecting changes:
   - Use the target major version and Git ref supplied in the request.
   - If no target ref is supplied, use the current worktree. If no target major is supplied, use the major immediately after the highest stable release tag (`git tag | sort -V`; tags are `vX.Y.Z`).
   - Use the latest stable release tag of the immediately preceding major as the baseline.
   - Record inferred versions, refs, and release scope as assumptions and continue.
3. Read the existing guides in `pubnub/doc/migration/`, giving the latest the most weight. Use them for structure, scope, and tone, not as evidence that a change applies to the target release. If none exist yet, follow the conventions reference alone.
4. Build a candidate inventory from independent repository sources. Run every command from the repository root.
   - **Export surface diff.** This is the primary signal.
     - Diff the consumer libraries: `git diff <baseline>..<target> -- pubnub/lib/pubnub.dart pubnub/lib/crypto.dart pubnub/lib/logging.dart pubnub/lib/networking.dart`.
     - Every name removed from a `show` list, and every removed or renamed `export`, is a candidate.
   - **Public declaration diff.**
     - Diff `pubnub/lib/src/` between the refs and restrict attention to exported declarations.
     - Look for removed or renamed classes, members, named parameters, and enum values; changed parameter types, nullability, or defaults; new required parameters; changed return types (`Future<T>` vs `Stream<T>`, result fields); and changed thrown exception types.
     - Check new `sealed`, `final`, `base`, or `interface` class modifiers, new abstract members on interfaces consumers implement (`INetworkingModule`, `IParserModule`, `ICryptoModule`, `ICryptor`, `ILogger`), new subtypes of the sealed `SubscriptionEvent` or `ObjectsEvent`, and new enum values used in exhaustive switches.
   - **Deprecations.** Run `git diff <baseline>..<target> -G'@Deprecated' -- pubnub/lib`. Record deprecations added in the target, and removals of APIs deprecated earlier.
   - **Optional tool.** If `dart_apitool` is already installed (`dart pub global list`), run it from `pubnub/`: `dart pub global run dart_apitool:main diff --old pub://pubnub/<baseline-version> --new .`. Treat its output as candidates, not verified claims. Do not install it without asking. If the command fails, record the failure and continue.
   - **Distribution and compatibility.** Compare `pubnub/pubspec.yaml` (`environment: sdk` lower bound, dependency majors that leak into the public API), the supported platforms in `README.md`, and VM, web, and WASM support.
   - **Behavior.** Check changed defaults: `RetryPolicy` and `NetworkingModule` options, crypto module selection in `PubNub(...)`, keyset `settings` defaults, and HTTP/2 enablement.
   - **Focused history.** Inspect commit history (`git log <baseline>..<target> -- <path>`) only when you need to establish intent, consumer impact, or the supported replacement.
   - **Excluded sources.** Do not use `.pubnub.yml`, `pubnub/CHANGELOG.md`, or other release-bot output as evidence.
5. Classify every candidate:
   - Include a breaking change when existing consumer code, configuration, dependency resolution, or documented behavior requires action.
   - Include a deprecation introduced by the target release when consumers should start migrating to a supported replacement.
   - Include an additive change only when it can break valid code, such as a new `SubscriptionEvent` subtype that breaks an exhaustive `switch`, or a new abstract member on an interface that consumers implement.
   - Exclude ordinary features, fixes that restore existing behavior, implementation refactors, tests, tooling, and changes that require no consumer migration.
   - Exclude `@nodoc` symbols and anything reachable only through `package:pubnub/core.dart` or `package:pubnub/src/...`, unless the request explicitly includes them. Those imports are not supported API.
6. Verify each included claim against the target source and its consumer-facing usage: tests, snippets in `pubnub/example/`, and public docs. Confirm the old form, the replacement, the affected conditions, and any behavior that remains compatible. Do not infer a migration from a symbol name or diff alone.
7. Draft the guide at `pubnub/doc/migration/PubNub_<major>_0_Migration_Guide.md`, unless the request names another destination. Preserve an existing draft's accurate content and unrelated edits.
8. Report the candidate inventory with the draft:
   - Included changes and their evidence.
   - Excluded candidates and the reason for exclusion.
   - Assumptions and unresolved candidates.

## Boundaries

- Never silently include an ambiguous or internal item. Keep it out of the draft, record it as unresolved, and complete the rest of the workflow.
- Do not turn the guide into release notes or a complete list of changes.
- Do not describe internal mechanisms when a consumer-visible consequence is sufficient.
- Do not promise compatibility, behavior, or replacement APIs that the source does not verify.
- Limit documentation changes to the target migration guide. Do not modify the changelog, `.pubnub.yml`, `dartdoc_options.yaml`, or other migration guides.
