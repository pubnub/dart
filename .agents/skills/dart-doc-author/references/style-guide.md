# PubNub dartdoc style guide

Use this guide when creating or reviewing `///` documentation comments for the PubNub Dart SDK. It applies [Effective Dart: Documentation](https://dart.dev/effective-dart/documentation) to this repository.

## Contract-first test

Include information when it helps answer:

- What does this API represent or do?
- When should a caller use it?
- What changes or happens after using it?
- What do special values such as `null`, `0`, or an empty collection mean?
- When does the returned `Future` complete, and with which exception does it fail?
- Is the stream a broadcast stream? When does it close? Does it replay past events?
- Can the operation be repeated, paused, cancelled, restored, or disposed?
- Is data stored, retained, or delivered later?
- Which keyset setting, module, or platform enables or changes the behavior?
- Which related API provides a meaningfully different behavior?

Usually exclude a fact when the implementation could change without changing anything callers observe.

For example, document that `Subscription.cancel()` closes every stream of the subscription. Do not document which controller it closes.

## Comment shape

Use only the paragraphs that add information. dartdoc has no `@param` or `@return` tags; refer to parameters in prose with square brackets.

```dart
/// <One sentence: what the symbol is or does.>
///
/// <When to use it, and caller-visible behavior that needs explanation.
/// Reference parameters as [channel] and other symbols as [Subscription].>
///
/// <Defaults, special values, conditions, lifecycle, side effects, or
/// alternatives.>
///
/// Throws [InvariantException] if [channel] is empty.
///
/// Example:
/// ```dart
/// var result = await pubnub.publish('my-channel', {'text': 'hello'});
/// ```
///
/// {@category Basic Features}
```

- Start with a single-sentence summary that ends with a period, followed by a blank `///` line.
- Use `///`, never `/** */`.
- Write throws as prose: `Throws [X] if …`. Name only exceptions the code actually throws for that condition.
- Code samples use `Example:` followed by a ```` ```dart ```` fence, as in `lib/src/dx/publish/publish.dart`. Samples must compile against the current public API. Use `pubnub` as the client variable.
- Put `{@category …}` last in a **class**, **enum**, **mixin**, or **extension** comment. Use only categories configured in `pubnub/dartdoc_options.yaml`: `Basic Features`, `Objects`, `DataSync`, `Files`, `Push`, `Access Manager`, `Exceptions`, `Results`, `Modules`. Do not add a category to a member.

## Summary conventions

Classes and other types use a noun phrase:

```dart
/// A subscription to a set of channels and channel groups.
```

Methods and functions start with a third-person verb:

```dart
/// Publishes [message] to [channel].
```

A method whose main purpose is its return value may start with "Returns":

```dart
/// Returns a real-time handle for the DataSync user [id].
```

Non-boolean properties use a noun phrase:

```dart
/// The cipher key used to encrypt and decrypt payloads for this keyset.
```

Boolean properties start with "Whether", followed by what `true` means:

```dart
/// Whether this subscription has been cancelled.
```

Enum values describe their meaning or effect:

```dart
/// Retries with a delay that grows exponentially with each attempt.
```

Avoid empty summaries such as "The channel.", "Message callback.", "Default constructor.", or "Whether the option".

## Parameters, results, and errors

Describe a parameter's purpose and behavioral effect, not its type:

```dart
/// Set [storeMessage] to `false` to skip storing the message in history.
/// Leave it `null` to use the keyset's configuration.
```

Document special values where they change behavior:

```dart
/// If [ttl] is `0`, the stored message does not expire.
```

Describe what a returned value means to the caller:

```dart
/// The returned [Subscription] is inactive until you call
/// [Subscription.subscribe].
```

Document verified failure conditions, not "throws on error":

```dart
/// Throws [ForbiddenException] if the token does not grant `write` on
/// [channel].
```

Do not invent an exhaustive error list when the implementation does not guarantee one.

### Keyset resolution

Most API methods take `keyset` and `using`. Existing comments repeat this paragraph:

```dart
/// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
/// If that fails, then it uses the default keyset.
/// If that fails as well, then it will throw [InvariantException].
```

Keyset lookup actually throws [KeysetException] (`lib/src/core/keyset/store.dart`). In new and edited comments, name `[KeysetException]`. Where a `{@template}` already holds the paragraph, as `pubnub.datasync.handle` does in `lib/src/default.dart`, fix it in the template.

## Shared text

Use templates for text that several declarations share:

```dart
/// {@template pubnub.subscribe.withProjection}
/// Set [withProjection] to observe a DataSync projection: ...
/// {@endtemplate}
Subscription subscribe(...);

/// {@macro pubnub.subscribe.withProjection}
Subscription subscription(...);
```

- Name templates `pubnub.<area>.<topic>`, and keep existing names stable.
- Put the `{@template}` on the most prominent declaration. Use `{@macro}` everywhere else.
- Bracket references inside a template resolve where the macro is used, so use only names valid at every use site.
- Document behavior shared by the typed streams of `Subscription` (`messages`, `presence`, `signals`, …) once, on `events` or the class, and give each getter only what it emits.

## Internals and visibility

- Mark public-but-internal declarations with a `/// @nodoc` line. dartdoc then omits them. `core.dart` is also excluded through `dartdoc_options.yaml`.
- Do not link consumer docs to `@nodoc` symbols, `*Params` classes, `Fiber`, `Manager`, `SubscribeLoop`, `Ensure`, or `defaultFlow`.
- Do not mention AES-GCM encryption. `AesGcmCryptor` is decrypt-only and unexported.

## Deprecations

Keep the `@Deprecated('…')` message as the place for the migration hint. In the doc comment, add a sentence that names the replacement as a link:

```dart
/// Use [CryptoModule.aesCbcCryptoModule] instead.
@Deprecated('Use CryptoModule.aesCbcCryptoModule for new applications. ...')
factory CryptoModule.legacyCryptoModule(CipherKey cipherKey, ...)
```

## Before and after

Weak:

```dart
/// Pause subscription.
void pause()
```

Contract-first:

```dart
/// Stops delivering events to this subscription without cancelling it.
///
/// The subscription may miss events that are published while it is paused.
/// Call [resume] to receive events again, or [cancel] to stop
/// permanently.
///
/// If the subscription is already paused, this method does nothing.
void pause()
```

Implementation-focused (wrong):

```dart
/// Removes the subscription's channels from the manager and updates the loop state.
void pause()
```

The manager and loop are irrelevant to callers and must not appear in public documentation.

## Review checklist

Before finishing, confirm:

- The summary sentence communicates purpose or effect without the declaration.
- Every behavioral claim is supported by source, tests, or established public documentation.
- Conditions that enable or disable behavior remain explicit.
- Constructor defaults were inspected wherever defaults are mentioned.
- `null`, zero, and empty-value behavior is documented when significant.
- Shared text lives in one `{@template}` or on the owning type.
- Every `[reference]` resolves, and every named parameter in prose exists.
- Named exceptions match what the code throws, including `KeysetException` for keyset resolution.
- Code samples compile.
- New classes carry a configured `{@category}`.
- Internal mechanisms, `@nodoc` symbols, and unreleased features are absent.
