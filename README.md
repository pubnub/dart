<img width="1920" height="600" alt="image" src="https://github.com/user-attachments/assets/799d7a8a-79f0-420d-a809-ffcbcf3dfb03" />

# PubNub Dart and Flutter SDK

[pubnub](pubnub/) [![Pub Version](https://img.shields.io/pub/v/pubnub)](https://pub.dev/packages/pubnub)

The PubNub SDK for Dart and Flutter applications on Android, iOS, Linux, macOS, web, and Windows.

[Documentation](https://www.pubnub.com/docs/sdks/dart) · [API reference](https://www.pubnub.com/docs/sdks/dart/api-reference/publish-and-subscribe) · [Changelog](https://www.pubnub.com/docs/sdks/dart/changelog)

## Requirements

- **Dart SDK:** [Dart 3.2 or later](https://pub.dev/packages/pubnub)
- **Supported targets:** [Android, iOS, Linux, macOS, web, and Windows](https://www.pubnub.com/docs/sdks/dart)
- **Platform network access:** Android requires `android.permission.INTERNET`. A sandboxed macOS app requires the `com.apple.security.network.client` entitlement. iOS requires no extra Internet permission.

## Install

From the root of the Dart package:

```sh
dart pub add pubnub
```

Environment setup: [Dart SDK guide](https://www.pubnub.com/docs/sdks/dart).

## Example

This example runs in a standalone Dart package.

If Access Manager is enabled, obtain a token from your trusted backend and call `pubnub.setToken(token)`. Keep the secret key on the backend.

Create a Dart package, then save the example as `bin/pubnub_example.dart`:

```dart
import 'dart:async';

import 'package:pubnub/pubnub.dart';

Future<void> main() async {
  final pubnub = PubNub(
    defaultKeyset: Keyset(
      subscribeKey: 'YOUR_SUBSCRIBE_KEY',
      publishKey: 'YOUR_PUBLISH_KEY',
      userId: UserId('hello-world-user'),
    ),
  );

  final subscription = pubnub.subscribe(
    channels: {'hello_world'},
  );

  final received = Completer<void>();

  final listener = subscription.messages.listen((message) {
    print(message.content);

    if (!received.isCompleted) {
      received.complete();
    }
  });

  await Future<void>.delayed(const Duration(seconds: 1));

  await pubnub.publish(
    'hello_world',
    'Hello world',
  );

  await received.future.timeout(const Duration(seconds: 10));

  await listener.cancel();
  await subscription.dispose();
}
```

## Run

```sh
dart run bin/pubnub_example.dart
```

Expected output in the terminal:

```text
Hello world
```

The example cancels the Dart Stream listener and calls `subscription.dispose()` after receiving the message.

Full guide: [Dart SDK documentation](https://www.pubnub.com/docs/sdks/dart).

## Next steps

| Task | Guide |
| --- | --- |
| Configure the client | [Configuration](https://www.pubnub.com/docs/sdks/dart/api-reference/configuration) |
| Work with subscriptions and messages | [Publish & Subscribe](https://www.pubnub.com/docs/sdks/dart/api-reference/publish-and-subscribe) |
| Check channel occupancy | [Presence](https://www.pubnub.com/docs/sdks/dart/api-reference/presence) |
| Read message history | [Message Persistence](https://www.pubnub.com/docs/sdks/dart/api-reference/storage-and-playback) |

Access Manager: [Access Manager](https://www.pubnub.com/docs/sdks/dart/api-reference/access-manager).

## Client lifetime and delivery

Reuse the PubNub client for the application/session lifetime. Cancel owned Stream listeners and call `subscription.dispose()` when a subscription is no longer needed.

Live delivery through PubNub SDKs is at-most-once. A subscriber can miss messages while disconnected or if its buffer overflows. For longer-gap recovery, see [Message Persistence](https://www.pubnub.com/docs/sdks/dart/api-reference/storage-and-playback).

## Troubleshooting

**Dart cannot resolve `package:pubnub`**

Run the example inside a Dart package with a `pubspec.yaml`, install the dependency, and run it with `dart run`. See the [Dart SDK guide](https://www.pubnub.com/docs/sdks/dart).

**A sandboxed macOS Flutter application fails PubNub requests**

Enable outbound networking with `com.apple.security.network.client` in both macOS entitlement files and rebuild. See the [Dart SDK guide](https://www.pubnub.com/docs/sdks/dart).

In Flutter, retain the PubNub client and subscription in the owning State or service object. Cancel the Stream listener and dispose the subscription during lifecycle cleanup instead of accumulating subscriptions across rebuilds.

More troubleshooting: [Dart SDK guide](https://www.pubnub.com/docs/sdks/dart).

## Changelog

[Changelog](https://www.pubnub.com/docs/sdks/dart/changelog)

For a major version change, review the [Dart SDK changelog](https://www.pubnub.com/docs/sdks/dart/changelog) for breaking changes before upgrading.

## Contributing

Report issues at [github.com/pubnub/dart/issues](https://github.com/pubnub/dart/issues).

Run `dart pub get`, generate required sources with the repository's build_runner workflow, run the Dart test suite, and include tests for behavioral changes before opening a pull request.

## License

[PubNub Software Development Kit License](https://github.com/pubnub/dart/blob/master/LICENSE)
