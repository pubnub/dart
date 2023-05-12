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

```dart
/*A Subscription contains a Dart Stream of messages from the channel(s) to which you are subscribed. You can transform that stream in the usual ways, or add a listener using listen:*/
  subscription.messages.listen((envelope) {
    switch (envelope.messageType) {
      case MessageType.normal:
          print('${envelope.publishedBy} sent a message: ${envelope.content}');
          break;
      case MessageType.signal:
          print('${envelope.publishedBy} sent a signal message: ${envelope.content}');
        break;
      case MessageType.objects:
          print('object event received from ${envelope.publishedBy} with data ${envelope.payload['data']}');
        break;
      case MessageType.messageAction:
          print('message action event ${envelope.payload['event']} received with data ${envelope.payload['data']}');
        break;
      case MessageType.file:
          var fileInfo = envelope.payload['file'];
          var id = fileInfo['id']; // unique file id
          var name = fileInfo['name']; // file name
          print('${envelope.publishedBy} sends file $name with message  ${envelope.payload['message']}');
        break;
      default:
        print('${envelope.publishedBy} sent a message: ${envelope.content}');
    }
  });

  subscription.presence.listen((event) {
      print('''Presence Event with action: ${event.action},
      received from uuid: ${event.uuid}
      with time token: ${event.timetoken},
      Total Occupancy now is: ${event.occupancy}
      ''');
  });

var envelope =
    await subscription.messages.firstWhere((envelope) => envelope.channel == 'my_channel');
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
