<img width="1920" height="600" alt="image" src="https://github.com/user-attachments/assets/799d7a8a-79f0-420d-a809-ffcbcf3dfb03" />

# PubNub Dart and Flutter SDK

[![Pub Version](https://img.shields.io/pub/v/pubnub)](https://pub.dev/packages/pubnub)

PubNub provides global infrastructure for real-time, interactive applications.

Publish and receive messages in Dart and Flutter. Use this SDK for Dart and Flutter applications on Android, iOS, Linux, macOS, web, and Windows.

[Documentation](https://www.pubnub.com/docs/sdks/dart) · [API reference](https://www.pubnub.com/docs/sdks/dart/api-reference/publish-and-subscribe) · [Changelog](https://www.pubnub.com/docs/sdks/dart/changelog) · [Support](https://support.pubnub.com/)

## Requirements

| Requirement | Supported version or setup |
| --- | --- |
| Dart SDK | [Dart 3.2 or later](https://pub.dev/packages/pubnub) |
| Supported targets | [Android, iOS, Linux, macOS, web, and Windows](https://www.pubnub.com/docs/sdks/dart) |
| Platform network access | Android requires `android.permission.INTERNET`. A sandboxed macOS app requires the `com.apple.security.network.client` entitlement. iOS requires no extra Internet permission. |

## Installation

From the root of the Dart package:

```sh
dart pub add pubnub
```

For other installation methods, see [environment setup](https://www.pubnub.com/docs/sdks/dart).

## Quickstart

This example runs in a standalone Dart package. It subscribes to `hello_world`, publishes one message, and prints the received text.

### Get your keys

1. Open the [PubNub Admin Portal](https://admin.pubnub.com/).
2. Create an app and a keyset for development, or select an existing development keyset.
3. Copy its publish key and subscribe key.

If Access Manager is enabled, obtain a token from your trusted backend and call `pubnub.setToken(token)`. Keep the secret key on the backend.

### Send and receive a message

Create a Dart package, then save the example as `bin/pubnub_example.dart`:

Replace the key placeholders. Use a User ID that identifies the user or device in your app.

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

### Run the example

```sh
dart run bin/pubnub_example.dart
```

The terminal should show:

```text
Hello world
```

The example cancels the Dart Stream listener and calls `subscription.dispose()` after receiving the message.

For a complete application, see the [getting started guide](https://www.pubnub.com/docs/sdks/dart).

## Next steps

| Task | Documentation |
| --- | --- |
| Configure the client | [Configuration](https://www.pubnub.com/docs/sdks/dart/api-reference/configuration) |
| Work with subscriptions and messages | [Publish & Subscribe](https://www.pubnub.com/docs/sdks/dart/api-reference/publish-and-subscribe) |
| Check channel occupancy | [Presence](https://www.pubnub.com/docs/sdks/dart/api-reference/presence) |
| Read message history | [Message Persistence](https://www.pubnub.com/docs/sdks/dart/api-reference/storage-and-playback) |

## Build with an AI coding assistant

The PubNub MCP server gives an AI coding assistant access to PubNub SDK documentation and PubNub APIs. Connect the assistant to the hosted server at [https://mcp.pubnub.com](https://mcp.pubnub.com), or run `npx @pubnub/mcp@latest` locally.

The [server repository](https://github.com/pubnub/pubnub-mcp-server) has setup steps for VS Code, Cursor, Claude Code, Claude Desktop, Codex, Gemini CLI, and OpenCode.

## Before production

Use [Access Manager](https://www.pubnub.com/docs/sdks/dart/api-reference/access-manager) to grant each client the permissions it needs. Keep the secret key on your backend. Never include it in a distributed client.

Reuse the PubNub client for the application/session lifetime. Cancel owned Stream listeners and call `subscription.dispose()` when a subscription is no longer needed.

Live delivery through PubNub SDKs is at-most-once. A subscriber can miss messages while disconnected or if its buffer overflows. For longer-gap recovery, see [Message Persistence](https://www.pubnub.com/docs/sdks/dart/api-reference/storage-and-playback).

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Dart cannot resolve `package:pubnub` | Run the example inside a Dart package with a `pubspec.yaml`, install the dependency, and run it with `dart run`. See the [Dart SDK guide](https://www.pubnub.com/docs/sdks/dart). |
| A publish succeeds but no message appears | Check the message handler, subscription readiness, keyset, and channel name. |
| A sandboxed macOS Flutter application fails PubNub requests | Enable outbound networking with `com.apple.security.network.client` in both macOS entitlement files and rebuild. See the [Dart SDK guide](https://www.pubnub.com/docs/sdks/dart). |
| Extra clients or duplicate messages during development | In Flutter, retain the PubNub client and subscription in the owning State or service object. Cancel the Stream listener and dispose the subscription during lifecycle cleanup instead of accumulating subscriptions across rebuilds. |

For setup help, see [troubleshooting](https://www.pubnub.com/docs/sdks/dart). Check [network status](https://status.pubnub.com/) for service incidents.

## Releases

Read the [changelog](https://www.pubnub.com/docs/sdks/dart/changelog) before upgrading.

For a major version change, review the [Dart SDK changelog](https://www.pubnub.com/docs/sdks/dart/changelog) for breaking changes before upgrading.

## Support and contributions

For setup or account help, contact [PubNub Support](https://support.pubnub.com/).

For a reproducible SDK bug, use [GitHub Issues](https://github.com/pubnub/dart/issues). Include the SDK version, runtime, and a small reproduction with credentials removed.

Run `dart pub get`, generate required sources with the repository's build_runner workflow, run the Dart test suite, and include tests for behavioral changes before opening a pull request.

## License

See the [PubNub Software Development Kit License](https://github.com/pubnub/dart/blob/master/LICENSE).
