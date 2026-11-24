# Coding Standards

This document is the source of truth for production Dart library code quality and style in this repository. Rules for test code live in the `dart-test-writer` skill (`.agents/skills/dart-test-writer/SKILL.md`). Rules for dartdoc comments live in the `dart-doc-author` skill. Repository layout, workflow, and validation commands live in `AGENTS.md`; module architecture lives in the module guides it links to.

## Production Dart Library Code

Apply these rules to production code under `pubnub/lib/`. They set the target for new and changed code; existing code is migrated gradually. Do not rewrite existing code to conform unless the task is about it, and never change the behavior or signature of a public API to satisfy a rule.

### Style and tooling

- Follow [Effective Dart](https://dart.dev/effective-dart). Let `dart format` decide layout; do not hand-format or fight it.
- Do not add `// ignore:` or `// ignore_for_file:` comments to silence the analyzer. The one accepted suppression is `// ignore: deprecated_member_use_from_same_package` on internal uses of the SDK's own deprecated API.
- Name new files in snake_case. Name types `UpperCamelCase`, members and locals `lowerCamelCase`, and constants `lowerCamelCase`; do not add new `SCREAMING_CAPS` constants.

### Declarations and visibility

- Use `final` for fields and locals that are not reassigned, and `const` constructors and values where possible.
- Make helpers library-private with a leading `_` unless another library needs them.
- Public API is what `lib/pubnub.dart`, `lib/crypto.dart`, `lib/logging.dart`, or `lib/networking.dart` exports. Add a new consumer-facing symbol to the matching library's `show` list. Do not export a whole `src/` file without `show`.
- Mark a type or member that must be `public` for cross-library use but is not consumer API with `/// @nodoc`, and do not export it from a consumer library.
- Do not widen the visibility of an existing declaration, and do not add a symbol to an export list, without noting it in the PR description.
- Do not introduce a new `abstract class`, `interface class`, or mixin unless at least two production types implement it, or a test double requires it.

### Null safety and types

- Do not introduce the `!` null assertion operator unless a check in the same scope proves the value is non-null. Prefer local promotion, `??`, or `?? (throw …)` with a `PubNubException`.
- Do not introduce `late` fields unless every constructor path initializes them before first read.
- Keep `dynamic` at the JSON boundary. `fromJson` factories read the decoded object and expose typed fields; do not leak `dynamic` into public signatures that did not already have it.
- Represent new timetoken values with `Timetoken` or `BigInt`, never `int`: a 17-digit timetoken loses precision as a JavaScript number on the web.
- Write JSON mapping by hand with `fromJson` factories and `toJson` methods. Do not introduce code generation (`build_runner`, `json_serializable`, `*.g.dart`).

### Errors

- Throw only `PubNubException` subclasses from public API (see `lib/src/core/AGENTS.md` for the hierarchy). Do not throw `String`, `Exception('…')`, or `Error` subclasses for conditions callers can recover from.
- Validate public method arguments with `Ensure` (`lib/src/dx/_utils/ensure.dart`) before doing any work, so invalid input fails with `InvariantException`.
- Do not introduce an empty `catch`, or a `catch` that discards an error the caller or user needs to know about. When converting an error into another type, keep the original message and stack trace (`Error.throwWithStackTrace`, or the `StackTrace` parameter of `PubNubException`).
- Keep crypto failures opaque to callers. Log the cause; do not put it in the exception message.

### Asynchrony

- Return `Future<T>` from one-shot operations and broadcast `Stream<T>` from real-time sources.
- Await every `Future`. When a future is intentionally not awaited, wrap it in `unawaited(...)` from `dart:async`.
- Do not use `Future.delayed`, timers, or polling to wait for state that another operation will signal; complete a `Completer` or emit on a stream instead. Delays are only for deliberate backoff, owned by the supervisor's `RetryPolicy`.
- Close every `StreamController` you create in the owning object's `cancel`, `dispose`, or equivalent lifecycle method.

### Platforms

- Platform-neutral code must not import `dart:io`, `dart:html`, `dart:js`, `dart:js_util`, or `package:js`. Put platform code behind the conditional-export pattern described in `lib/src/networking/AGENTS.md`, using `package:web` and `dart:js_interop` on the web so that dart2wasm keeps working.

### Logging and secrets

- Get a logger with `final _logger = injectLogger('pubnub.<area>')` at the top of the file, and log API parameters as a structured `LogEvent` with the matching `LogEventDetailsType`.
- Never log or include in exception messages a `secretKey`, `cipherKey`, `authKey`, access token, or decrypted payload.

### Deprecation

- Deprecate with `@Deprecated('Use <replacement> instead. <Old API> will be removed in a future release.')`. Do not use the lowercase `@deprecated` constant.
- Keep a deprecated API working until a major release removes it.
