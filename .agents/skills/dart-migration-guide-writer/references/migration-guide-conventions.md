# PubNub Dart migration guide conventions

Use these conventions when drafting or reviewing a major-version migration guide.

## Purpose and scope

A migration guide is an action-oriented document for consumers who upgrade from the latest release of the previous major version. It is not a release summary.

Include:

- Source-breaking public API changes: removed or renamed exports, members, and named parameters; changed types, nullability, defaults, and return types; new required parameters.
- Changes that break exhaustive `switch` statements or consumer implementations: new subtypes of a sealed class, new enum values, new abstract interface members, new class modifiers.
- Package changes that require consumer action: the Dart SDK lower bound, dependency constraints that conflict with common apps, platform support (VM, web with dart2js and dart2wasm, Flutter targets).
- Behavior changes that require consumers to change code or expectations, such as a different thrown exception type or a changed retry or crypto default.
- Deprecations introduced in the target major that have a verified, supported replacement.

Exclude:

- New features that do not affect existing code.
- Bug fixes that restore the documented contract.
- Internal implementation changes, `@nodoc` symbols, and APIs reachable only through `package:pubnub/core.dart` or `package:pubnub/src/...`.
- Test, build, CI, documentation-tooling, and repository-maintenance changes.
- Deprecations that already existed at the baseline.

## Document shape

Follow this naming convention:

```text
pubnub/doc/migration/PubNub_<major>_0_Migration_Guide.md
```

Use this overall structure, omitting empty sections:

````markdown
# PubNub Dart SDK <major>.0 Migration Guide

<Introduction: what the major release covers, the supported Dart SDK range and platforms, Semantic Versioning context, and the purpose of this guide.>

## Requirements

<Only if the Dart SDK lower bound, platforms, or dependency constraints changed: what consumers must update in their pubspec.yaml or toolchain.>

## Breaking API Changes

### 1. <Consumer-facing change>

<Impact, affected users, and required migration.>

```dart
// Before (<previous major>.x):
...

// Now (<major>.0):
...
```

## Deprecations (Non-Breaking Changes)

### <Deprecated API>

<What is deprecated, what replaces it, and whether existing code still works.>
````

The requirements and deprecations sections are optional. Include each one only when the target major has relevant items; otherwise omit the whole section. Do not repeat deprecations that already existed at the baseline.

Derive the supported SDK range and platform list from the target repository state (`pubnub/pubspec.yaml`, `README.md`). Do not copy them from an older guide.

## Writing each change

Start with the consumer-visible difference. Then explain:

1. Who is affected, or when the change matters.
2. What no longer compiles, analyzes cleanly, or behaves as before.
3. The supported replacement or action.
4. What remains compatible, when that prevents unnecessary migration work.

Use before-and-after Dart examples when they make the required edit clearer. Keep examples focused on the changed API, import only `package:pubnub/pubnub.dart` (or the relevant consumer library), and verify symbol names, named parameters, and defaults against both refs.

For a new sealed subtype, show the exhaustive `switch` that stops compiling and the added `case`:

```dart
switch (event) {
  case MessageEvent(:final message):
    ...
  case NewEvent():   // Required in <major>.0.
    ...
}
```

Use a note near the start of a section when only some consumers are affected:

```markdown
> **Note:** Skip this section if you do not provide a custom `INetworkingModule`.
```

Group tightly related changes that consumers migrate together. Keep unrelated migration actions in separate sections.

## Tone

- Write directly to SDK consumers.
- Prefer precise statements such as "is no longer exported from `package:pubnub/pubnub.dart`" or "pass the value to the `Keyset` constructor".
- Explain consequences instead of implementation mechanics.
- Keep headings descriptive and examples practical.
- Wrap prose at 120 characters. Do not force-wrap headings, tables, fenced code, or links.
- When editing an existing guide, do not reflow unchanged paragraphs.
- Avoid promotional language and exhaustive inventories of new functionality.
- Do not claim that a guide is complete; it covers changes that require migration.

## Candidate report

Keep the analysis outside the guide. For each candidate, record:

- The affected public API or package surface.
- Evidence from the comparison: the diff hunk, tool output, or source location.
- The consumer impact.
- The replacement or migration action.
- Its disposition: include, exclude with a reason, or unresolved.

Keep an ambiguous candidate out of the draft, record it as unresolved, and continue. This includes changes whose public status, release scope, compatibility impact, or supported replacement cannot be verified.
