@TestOn('vm')
@Tags(['integration'])

import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_utils.dart';

void main() {
  late String channel;

  final PRODUCER = UUID('PRODUCER');

  final SUBSCRIBE_KEY = Platform.environment['SDK_SUB_KEY'] ?? 'demo';
  final PUBLISH_KEY = Platform.environment['SDK_PUB_KEY'] ?? 'demo';

  var keyset = Keyset(
      subscribeKey: SUBSCRIBE_KEY, publishKey: PUBLISH_KEY, uuid: PRODUCER);

  group('Presence', () {
    late PubNub pubnub;
    late PresenceConsumer consumer;

    setUp(() async {
      channel =
          'dart-presence-test-${Random().nextInt(99999).toString().padLeft(5, '0')}';

      pubnub = PubNub(defaultKeyset: keyset);

      consumer = PresenceConsumer.setup(pubnub, SUBSCRIBE_KEY);
    });

    test('should send a leave event after announce leave call', () async {
      consumer.start(channel, fromUUID: PRODUCER);

      await pubnub.announceHeartbeat(channels: {channel}, heartbeat: 20);

      await consumer.expectEvent(
        action: PresenceAction.join,
        uuid: PRODUCER,
      );

      await Future.delayed(Duration(seconds: 5));

      await pubnub.announceLeave(channels: {channel});

      await consumer.expectEvent(
        action: PresenceAction.leave,
        uuid: PRODUCER,
      );
    });

    test(
        'should send a timeout event after heartbeat specified in heartbeat call',
        () async {
      consumer.start(channel, fromUUID: PRODUCER);

      await pubnub.announceHeartbeat(channels: {channel}, heartbeat: 20);

      await consumer.expectEvent(
        action: PresenceAction.join,
        uuid: PRODUCER,
      );

      await consumer.expectEvent(
        action: PresenceAction.timeout,
        uuid: PRODUCER,
        within: Duration(seconds: 25),
      );
    });

    test(
        'should send a timeout event after subscribing with heartbeat specified in the keyset',
        () async {
      consumer.start(channel, fromUUID: PRODUCER);

      keyset.heartbeatInterval = 20;

      var subscription = pubnub.subscribe(channels: {channel});

      await consumer.expectEvent(action: PresenceAction.join, uuid: PRODUCER);

      await consumer.expectEvent(
        action: PresenceAction.timeout,
        uuid: PRODUCER,
        within: Duration(seconds: 25),
      );

      await subscription.cancel();
    });

    tearDown(() async {
      await consumer.end();
      await pubnub.unsubscribeAll();
    });
  });
}
