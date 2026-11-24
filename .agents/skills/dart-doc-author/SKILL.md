---
name: dart-doc-author
description: Author or review contract-first dartdoc (///) comments for consumer-facing public APIs in the PubNub Dart SDK. Use for inline API documentation and generated API reference quality; do not use for general prose, README, changelog, release notes, or implementation comments.
---

# Dart doc author

Write documentation that reads like a well-kept pub.dev package: concise, precise, and focused on what callers observe. Follow [Effective Dart: Documentation](https://dart.dev/effective-dart/documentation), together with the repository conventions in the style guide.

## Core principles

> Document the public contract from the SDK consumer's perspective. Describe purpose, observable behavior, consequences, constraints, and lifecycle. Exclude implementation details unless they create a user-visible guarantee.

> Put shared behavior in one place. Use a `{@template}` on the owning declaration and `{@macro}` where the text repeats, or document it once on the owning class.

> Inspect how a symbol is initialized, consumed, and tested before documenting it. Do not infer its contract from its name, declaration, or apparent default value alone.

Conciseness must not remove conditions that change observable behavior.

## Workflow

1. Read the repository's `AGENTS.md`, `CODING_STANDARDS.md`, and the module guide (`pubnub/lib/src/<module>/AGENTS.md`) for the code you are documenting.
2. Confirm that the symbol is consumer API: `lib/pubnub.dart`, `lib/crypto.dart`, `lib/logging.dart`, or `lib/networking.dart` exports it. Being `public` is not enough. Leave symbols marked `/// @nodoc`, everything reachable only through `package:pubnub/core.dart`, and `*Params` classes undocumented for consumers unless the user explicitly includes them.
3. Trace the symbol before writing:
   - Inspect every constructor and named parameter default that can set its value.
   - Find reads, writes, callers, and related state, including keyset `settings` extensions.
   - Inspect focused tests in `pubnub/test/` and snippets in `pubnub/example/` for observable behavior and edge cases.
   - Check platform differences (VM and web), deprecation, `Future` completion and error behavior, stream broadcast and lifecycle, cancellation, and persistence where relevant.
4. Choose the place for shared rules. Prefer one `{@template}` for text that applies to several declarations, such as keyset resolution or projection rules, over copies.
5. Write only claims supported by code, tests, or established public documentation. If behavior remains ambiguous, keep the existing accurate wording or report the uncertainty instead of inventing a guarantee.
6. Make the first sentence a standalone summary. dartdoc shows it in member lists and IDE hovers. Add more paragraphs only when they help callers choose or use the API correctly.
7. Preserve snippet markers, `{@category}` tags, existing `{@template}` names, `@Deprecated` annotations, and unrelated user changes. Do not expose unreleased or internal features.
8. Validate proportionally:
   - Re-read edited comments beside their declarations.
   - Confirm that every `[name]` reference resolves to a parameter or a visible symbol.
   - Confirm that code samples compile against the current API.
   - Run `dart analyze --fatal-warnings lib`.
   - Run `dart doc --dry-run` from `pubnub/` when categories, templates, or library-level docs changed. Report any warnings it prints for the edited symbols. Until the missing `doc/DataSync.md` listed under Known Gaps in `AGENTS.md` is added, the command fails before generating docs. Report that, and rely on the other checks.

Before authoring or reviewing comments, read [the PubNub dartdoc style guide](references/style-guide.md).

## Boundaries

Do not:

- Restate a declaration without explaining its meaning or effect.
- Describe `defaultFlow`, fibers, request handlers, managers, the subscribe loop, serialization steps, or control flow.
- Promise ordering, retries, delivery, thread or isolate safety, or persistence unless verified.
- Copy the same paragraph onto every overload or stream getter instead of using a template.
- Treat a field initializer as the effective public default without inspecting the constructors.
- Document AES-GCM encryption, the v2 `grant` API, or any other `@nodoc` or unexported feature.
- Rewrite unrelated documentation merely to make wording uniform.

Implementation facts belong in dartdoc only when callers can observe or depend on their consequence. Describe the consequence, not the mechanism.
