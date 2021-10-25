import 'package:pubnub/pubnub.dart';

void main() async {
  // Create PubNub instance with default keyset.
  var pubnub = PubNub(
      defaultKeyset:
          Keyset(subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('demo')));

  // Subscribe to a channel
  var subscription = pubnub.subscribe(channels: {'test'});

  subscription.messages.take(1).listen((envelope) async {
    print(envelope.payload);

    await subscription.dispose();
  });

  await Future.delayed(Duration(seconds: 3));

  // Publish a message
  await pubnub.publish('test', {'message': 'My message!'});

  // Channel abstraction for easier usage
  var channel = pubnub.channel('test');

  await channel.publish({'message': 'Another message'});

  // Work with channel History API
  var history = channel.messages();
  var count = await history.count();

  print('Messages on test channel: $count');
}
