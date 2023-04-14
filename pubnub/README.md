# PubNub Dart SDK

[![Pub Version](https://img.shields.io/pub/v/pubnub)](https://pub.dev/packages/pubnub)

> `pubnub` is a Flutter-friendly SDK written in Dart that allows you to connect to PubNub Data Streaming Network and add real-time features to your application.

## Installation

### Using `pub` dependency management tool

`pubnub` uses the standard `pub` tool for package management to distribute Dart code.

To add the package to your Dart or Flutter project, add `pubnub` as a dependency in your `pubspec.yaml`.

```yaml
dependencies:
  pubnub: ^4.2.2
```

After adding the dependency to `pubspec.yaml`, run the `dart pub get` command in the root directory of your project (the same that the `pubspec.yaml` is in).

### Using Git

If you want to use the latest, unreleased version of `pubnub`, you can add it to `pubspec.yaml` as a Git package.

```yaml
dependencies:
  pubnub:
    git: git://github.com/pubnub/dart.git
    path: pubnub
```

### Using a local copy of the repository

If you want to copy the Dart repository and modify it locally, clone it using `git clone https://github.com/pubnub/dart` and then import it into `pubspec.yaml` as follows:

```yaml
dependencies:
  pubnub:
    path: ../path-to-cloned-pubnub-repo
```

## Importing

After you install the `pubnub` package, import it in your application.
You can import it in one of two ways:

```dart
// Import all PubNub objects into your namespace
import 'package:pubnub/core.dart';

// Or import PubNub into a named namespace
import 'package:pubnub/pubnub.dart' as pn;
```

## Usage

### Keyset

First, create a [`Keyset`](https://pub.dev/documentation/pubnub/latest/pubnub/Keyset-class.html) instance:

```dart
final myKeyset = Keyset(
  subscribeKey: 'demo',
  publishKey: 'demo',
  uuid: UUID('demo'));
```

`Keyset` contains all your configuration. You can use multiple Keysets (with different parameters) if you need.

If you have a PubNub account, replace `demo` with the key values from your [PubNub dashboard](https://dashboard.pubnub.com). If you don't, you can use the highly rate-limited `demo` keys, but be aware that the keyset is public, so don't send any sensitive data.

### PubNub instance

Next, instantiate the `PubNub` class, passing `myKeyset` as a default keyset. This will be used any time a keyset is not passed into a method.

```dart
final pubnub = PubNub(defaultKeyset: myKeyset);
```

Now you can use the `pubnub` instance to publish messages, subscribe to channels, and [everything else](https://pub.dev/documentation/pubnub/latest/pubnub/PubNub-class.html)!

### Publishing messages

To publish a message, use the `publish` method.

```dart
pubnub.publish('my_channel', { 'content': 'Hello world!' });
```

Messages can be any JSON-serializable object.

If you are going to publish a lot of messages to one channel, you can use `channel` abstraction to obtain an instance of a [`Channel`](https://pub.dev/documentation/pubnub/latest/pubnub/Channel-class.html).

```dart
final myChannel = pubnub.channel('my_channel');

myChannel.publish(200);
myChannel.publish({ 'answer': 42 });
```

### Subscribing to channels

To subscribe to a list of channels or channel groups, use the `subscribe` method.
You need to pass a `Set` of channels or channel groups.

```dart
var subscription = pubnub.subscribe(channels: {'ch1', 'ch2'});
```

You can also use your `Channel` instance:

```dart
var subscription = myChannel.subscribe();
```

Both of those methods return a [`Subscription`](https://pub.dev/documentation/pubnub/latest/pubnub/Subscription-class.html).

A Subscription contains a Dart `Stream` messages from the channel(s) to which you are subscribed. You can transform that stream in the usual ways, or add a listener using `listen`:

```dart
subscription.messages.listen((envelope) {
  print(`${envelope.uuid} sent a message: ${envelope.payload}`);
});

var envelope =
      await sub.messages.firstWhere((envelope) => envelope.channel == 'ch2');
```

### Channel history

You can retrieve past messages from a channel in two ways, as follows:

#### Using `channel.history`

Use this method if you want to fetch messages gradually. They are fetched in descending order (from newest to oldest) by default.

```dart
var history = myChannel.history(chunkSize: 50);

await history.more();
print(history.messages.length); // 50
await history.more();
print(history.messages.length); // 100
```

#### Using `channel.messages`

Use this method to fetch many messages at once.

```dart
var history = myChannel.messages(from: Timetoken(1234567890));

var count = await history.count();
print(count);

var messages = await history.fetch();
print(messages.length);

await history.delete(); // Beware! This will delete all messages matched
```

### Multiple keysets

There are two ways to use multiple keysets at the same time, as follows:

#### Using named keysets

You can add multiple keysets with a name to an instance of `PubNub`.

```dart
pubnub.keysets.add(myKeyset1, name: 'keyset1');
pubnub.keysets.add(myKeyset2, name: 'keyset2');
```

To use a named keyset instead of the default, pass its name in a `using:` parameter into one of the `pubnub` instance methods:

```dart
pubnub.publish('channel', 42, using: 'keyset1');
var myChannel = pubnub.channel('channel', using: 'keyset2');
```

#### Using a keyset instance

Instead of adding the keyset to `pubnub.keysets`, you can use the `keyset:` named parameter to pass a keyset instance directly to `pubnub` instance methods:

```dart
pubnub.subscribe(channels: {'channel'}, keyset: myKeyset1)
```

## Contributing

1. Clone the repository.

    ```bash
    git clone https://github.com/pubnub/dart.git
    ```

1. Enter the directory and install dependencies.

    ```bash
    cd dart
    dart pub get
    ```

1. Run the `build_runner` to generate necessary source files.

    ```bash
    dart pub run build_runner build
    ```
