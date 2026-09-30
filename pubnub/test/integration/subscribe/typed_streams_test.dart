@TestOn('vm')
@Tags(['integration'])

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

/// Generates every kind of real-time event on the live server and verifies
/// that each one is emitted on its own typed stream of a [Subscription] only.
void main() {
  final subscribeKey = Platform.environment['SDK_SUB_KEY'] ?? 'demo';
  final publishKey = Platform.environment['SDK_PUB_KEY'] ?? 'demo';
  const timeout = Duration(seconds: 15);

  late String channel;
  late UUID publisherUuid;
  late PubNub listener;
  late PubNub publisher;
  late Subscription subscription;

  /// Every event emitted on [Subscription.events].
  late List<SubscriptionEvent> events;

  /// Every envelope emitted on [Subscription.messages].
  late List<Envelope> messages;

  Future<void> listen({bool withPresence = false}) async {
    subscription =
        listener.subscribe(channels: {channel}, withPresence: withPresence);
    subscription.events.listen(events.add);
    subscription.messages.listen(messages.add);
    await subscription.whenStarts;
    // Let the long poll settle, so that events published next are delivered.
    await Future<void>.delayed(Duration(seconds: 2));
  }

  setUp(() {
    var suffix = Random().nextInt(99999).toString().padLeft(5, '0');
    channel = 'dart-typed-streams-$suffix';
    publisherUuid = UUID('dart-typed-publisher-$suffix');
    events = [];
    messages = [];

    listener = PubNub(
        defaultKeyset: Keyset(
            subscribeKey: subscribeKey,
            publishKey: publishKey,
            userId: UserId('dart-typed-listener-$suffix')));
    publisher = PubNub(
        defaultKeyset: Keyset(
            subscribeKey: subscribeKey,
            publishKey: publishKey,
            userId: UserId(publisherUuid.value)));
  });

  tearDown(() async {
    await listener.unsubscribeAll();
  });

  group('Subscription typed streams', () {
    test('published message is emitted on messages', () async {
      await listen();
      var queue = StreamQueue(subscription.messages);

      await publisher.publish(channel, {'text': 'hello'},
          meta: {'m': 1}, customMessageType: 'chat-msg');

      var envelope = await queue.next.timeout(timeout);
      expect(envelope.messageType, equals(MessageType.normal));
      expect(envelope.payload, equals({'text': 'hello'}));
      expect(envelope.uuid, equals(publisherUuid));
      expect(envelope.userMeta, equals({'m': 1}));
      expect(envelope.customMessageType, equals('chat-msg'));

      var event = events.single as MessageEvent;
      expect(event.message, equals({'text': 'hello'}));
      expect(event.publisher, equals(publisherUuid));
      expect(event.channel, equals(channel));

      await queue.cancel();
    });

    test('signal is emitted on signals only', () async {
      await listen();
      var queue = StreamQueue(subscription.signals);

      await publisher.signal(channel, 'typing',
          customMessageType: 'typing-sig');

      var event = await queue.next.timeout(timeout);
      expect(event.message, equals('typing'));
      expect(event.publisher, equals(publisherUuid));
      expect(event.customMessageType, equals('typing-sig'));
      expect(event.channel, equals(channel));

      expect(events, [same(event)]);
      expect(messages, isEmpty);

      await queue.cancel();
    });

    test('message action added and removed are emitted on messageActions only',
        () async {
      await listen();
      var queue = StreamQueue(subscription.messageActions);

      var published = await publisher.publish(channel, 'react to me');
      var messageTimetoken = Timetoken(BigInt.from(published.timetoken));

      var added = await publisher.addMessageAction(
          type: 'reaction',
          value: 'smile',
          channel: channel,
          timetoken: messageTimetoken);

      var addedEvent = await queue.next.timeout(timeout);
      expect(addedEvent.event, equals(MessageActionEventType.added));
      expect(addedEvent.action.type, equals('reaction'));
      expect(addedEvent.action.value, equals('smile'));
      expect(addedEvent.action.uuid, equals(publisherUuid.value));
      expect(addedEvent.messageTimetoken, equals(messageTimetoken));
      expect(addedEvent.action.actionTimetoken,
          equals(added.action.actionTimetoken));

      await publisher.deleteMessageAction(channel,
          messageTimetoken: messageTimetoken,
          actionTimetoken: addedEvent.actionTimetoken);

      var removedEvent = await queue.next.timeout(timeout);
      expect(removedEvent.event, equals(MessageActionEventType.removed));
      expect(removedEvent.action.value, equals('smile'));
      expect(removedEvent.actionTimetoken, equals(addedEvent.actionTimetoken));

      // Only the published message itself reaches `messages`.
      expect(messages.map((m) => m.payload), ['react to me']);
      expect(events.map((e) => e.runtimeType),
          [MessageEvent, MessageActionEvent, MessageActionEvent]);

      await queue.cancel();
    });

    test('file message is emitted on files only', () async {
      await listen();
      var queue = StreamQueue(subscription.files);

      await publisher.files.publishFileMessage(
          channel,
          FileMessage(FileInfo('dart-file-id', 'cat.png'),
              message: {'note': 'pic'}),
          customMessageType: 'file-msg');

      var event = await queue.next.timeout(timeout);
      expect(event.file!.id, equals('dart-file-id'));
      expect(event.file!.name, equals('cat.png'));
      expect(event.message, equals({'note': 'pic'}));
      expect(event.publisher, equals(publisherUuid));
      expect(event.customMessageType, equals('file-msg'));
      expect(event.error, isNull);
      expect(
          event.url,
          equals(
              listener.files.getFileUrl(channel, 'dart-file-id', 'cat.png')));

      expect(events, [same(event)]);
      expect(messages, isEmpty);

      await queue.cancel();
    });

    test('App Context changes are emitted on objects only', () async {
      await listen();
      var queue = StreamQueue(subscription.objects);

      try {
        await publisher.objects.setChannelMetadata(
            channel,
            ChannelMetadataInput(
                name: 'Typed streams', description: 'd', custom: {'k': 'v'}));
        var channelSet =
            await queue.next.timeout(timeout) as ChannelMetadataEvent;
        expect(channelSet.event, equals(ObjectsEventType.set));
        expect(channelSet.metadata.id, equals(channel));
        expect(channelSet.metadata.name, equals('Typed streams'));
        expect(channelSet.metadata.description, equals('d'));
        expect(channelSet.metadata.custom, equals({'k': 'v'}));
        expect(channelSet.metadata.eTag, isNotNull);

        // UUID metadata events are delivered on the channel named after the uuid.
        await publisher.objects.setUUIDMetadata(
            UuidMetadataInput(name: 'Typed user', custom: {'a': 1}),
            uuid: channel);
        var uuidSet = await queue.next.timeout(timeout) as UuidMetadataEvent;
        expect(uuidSet.event, equals(ObjectsEventType.set));
        expect(uuidSet.metadata.id, equals(channel));
        expect(uuidSet.metadata.name, equals('Typed user'));
        expect(uuidSet.metadata.custom, equals({'a': 1}));

        await publisher.objects.setMemberships([
          MembershipMetadataInput(channel, custom: {'role': 'admin'})
        ], uuid: publisherUuid.value);
        var membershipSet =
            await queue.next.timeout(timeout) as MembershipMetadataEvent;
        expect(membershipSet.event, equals(ObjectsEventType.set));
        expect(membershipSet.channelId, equals(channel));
        expect(membershipSet.uuid, equals(publisherUuid.value));
        expect(membershipSet.custom, equals({'role': 'admin'}));

        await publisher.objects
            .removeMemberships({channel}, uuid: publisherUuid.value);
        var membershipDelete =
            await queue.next.timeout(timeout) as MembershipMetadataEvent;
        expect(membershipDelete.event, equals(ObjectsEventType.delete));
        expect(membershipDelete.channelId, equals(channel));
        expect(membershipDelete.uuid, equals(publisherUuid.value));

        await publisher.objects.removeUUIDMetadata(uuid: channel);
        var uuidDelete = await queue.next.timeout(timeout) as UuidMetadataEvent;
        expect(uuidDelete.event, equals(ObjectsEventType.delete));
        expect(uuidDelete.metadata.id, equals(channel));
        expect(uuidDelete.metadata.name, isNull);

        await publisher.objects.removeChannelMetadata(channel);
        var channelDelete =
            await queue.next.timeout(timeout) as ChannelMetadataEvent;
        expect(channelDelete.event, equals(ObjectsEventType.delete));
        expect(channelDelete.metadata.id, equals(channel));

        expect(events.every((e) => e is ObjectsEvent), isTrue);
        expect(events, hasLength(6));
        expect(messages, isEmpty);
      } finally {
        await queue.cancel();
        await _ignoreErrors(publisher.objects
            .removeMemberships({channel}, uuid: publisherUuid.value));
        await _ignoreErrors(
            publisher.objects.removeUUIDMetadata(uuid: channel));
        await _ignoreErrors(publisher.objects.removeChannelMetadata(channel));
      }
    });

    test('presence events are emitted on presence only', () async {
      await listen(withPresence: true);
      var queue = StreamQueue(
          subscription.presence.where((event) => event.uuid == publisherUuid));

      await publisher.announceHeartbeat(channels: {channel}, heartbeat: 60);
      var join = await queue.next.timeout(timeout);
      expect(join.action, equals(PresenceAction.join));
      expect(join.channel, equals(channel));
      expect(join.envelope.channel, equals('$channel-pnpres'));
      expect(join.occupancy, greaterThanOrEqualTo(1));

      await publisher.setState({'mood': 'ok'}, channels: {channel});
      var stateChange = await queue.next.timeout(timeout);
      expect(stateChange.action, equals(PresenceAction.stateChange));
      expect(stateChange.state, equals({'mood': 'ok'}));

      await publisher.announceLeave(channels: {channel});
      var leave = await queue.next.timeout(timeout);
      expect(leave.action, equals(PresenceAction.leave));
      expect(leave.channel, equals(channel));

      expect(events.every((e) => e is PresenceEvent), isTrue);
      expect(messages, isEmpty);

      await queue.cancel();
    });
  });
}

/// Best effort cleanup — the object may have already been removed by the test.
Future<void> _ignoreErrors(Future<void> future) async {
  try {
    await future;
  } catch (_) {}
}
