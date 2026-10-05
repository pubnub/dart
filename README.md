<img width="1920" height="600" alt="image" src="https://github.com/user-attachments/assets/799d7a8a-79f0-420d-a809-ffcbcf3dfb03" />

# PubNub Dart SDK

This is the official PubNub Dart SDK repository. 

PubNub takes care of the infrastructure and APIs needed for the realtime communication layer of your application. Work on your app's logic and let PubNub handle sending and receiving data across the world in less than 100ms.

This repository contains the following packages:

* [pubnub](pubnub/) [![Pub Version](https://img.shields.io/pub/v/pubnub)](https://pub.dev/packages/pubnub) - a Flutter-friendly SDK written in Dart that allows you to connect to PubNub Data Streaming Network and add real-time features to your application.

* [pubnub_flutter](pubnub_flutter/) - a collection of widgets for PubNub Dart SDK that allows you to create PubNub powered cross-platform applications with ease.

## Get keys

You will need the publish and subscribe keys to authenticate your app. Get your keys from the [Admin Portal](https://dashboard.pubnub.com/login).

## Configure PubNub

1. Integrate the Dart SDK into your project using the pub package manager by adding the following dependency in your `pubspec.yml` file:

    ```yaml
    dependencies:
      pubnub: ^4.2.2
    ```

    Make sure to provide the latest version of the `pubnub` package in the dependency declaration.

2. From the directory where your `pubspec.yml` file is located, run the `dart pub get` or `flutter pub get` command to install the PubNub package.

3. Configure your keys:

    ```dart
    var pubnub = PubNub(
      defaultKeyset:
          Keyset(subscribeKey: 'mySubscribeKey', publishKey: 'myPublishKey', uuid: UUID('ReplaceWithYourClientIdentifier')));
    ```

## Add event listeners

`messages` emits published messages only. Each other kind has its own stream, and `events` delivers all of them as a typed `SubscriptionEvent`.

```dart
subscription.messages.listen((envelope) {
  print('${envelope.uuid} sent: ${envelope.content}');
});

subscription.signals.listen((signal) => print(signal.message));
subscription.messageActions.listen((action) => print(action.event));
subscription.files.listen((file) => print(file.file?.name));
subscription.objects.listen((object) => print(object.event));
subscription.dataSync.listen((change) => print('${change.event} ${change.id}'));
subscription.presence.listen((presence) => print(presence.action));

subscription.events.listen((event) {
  switch (event) {
    case MessageEvent(:final message):
      print(message);
    case DataSyncEvent(:final id):
      print(id);
    default:
  }
});
```

## Publish/subscribe

```dart
var channel = "getting_started";
var subscription = pubnub.subscribe(channels: {channel});

await pubnub.publish(channel, "Hello world");
```

## Documentation

* [API reference for Dart ](https://www.pubnub.com/docs/sdks/dart)

## Support

If you **need help** or have a **general question**, contact support@pubnub.com.
