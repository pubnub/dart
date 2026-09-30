@TestOn('vm')
@Tags(['integration'])

import 'package:async/async.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

/// Changes DataSync objects on the live server and verifies that the
/// real-time events are emitted on [Subscription.dataSync] only.
void main() {
  /// Subscribes to all the objects whose id starts with [prefix] and returns
  /// the DataSync events, all the subscription events and the messages.
  ///
  /// Events of an object are delivered on the channel named after its id, so
  /// a wildcard over the id prefix receives all of them.
  Future<(StreamQueue<DataSyncEvent>, List<SubscriptionEvent>, List<Envelope>)>
      listen(PubNub pubnub, String prefix) async {
    var events = <SubscriptionEvent>[];
    var messages = <Envelope>[];
    var subscription = pubnub.subscribe(channels: {'$prefix.*'});
    subscription.events.listen(events.add);
    subscription.messages.listen(messages.add);
    var queue = StreamQueue(subscription.dataSync);
    addTearDown(() => queue.cancel(immediate: true));
    await subscription.whenStarts;
    // The create event can only be seen once the long poll is established.
    await Future<void>.delayed(Duration(seconds: 3));
    return (queue, events, messages);
  }

  group('Subscription dataSync stream', () {
    test('emits entity create, update and delete events', () async {
      var (pubnub, cleanup) = testClient();
      var prefix = freshId('dartevt');
      var id = '$prefix.customer';
      var (queue, events, messages) = await listen(pubnub, prefix);

      var payload = customerPayload(id, {'creditScore': 700});
      var created = await pubnub.dataSync.createEntity(EntityInput(
          id: id,
          className: customerClass,
          classVersion: classVersion,
          payload: payload));
      cleanup.add(() => pubnub.dataSync.removeEntity(id));

      var create =
          await nextEvent(queue, eventFor(DataSyncEventType.create, id));
      expect(create.objectType, equals(DataSyncObjectType.entity));
      expect(create.channel, equals(id));
      expect(create.subscription, equals('$prefix.*'));
      expect(create.className, equals(customerClass));
      expect(create.classVersion, equals(classVersion));
      expect(create.classLevel, equals('SubKey'));
      expect(create.source, equals('data-sync'));
      expect(create.eTag, equals(created.entity.eTag));
      expect(create.payload, equals(payload));

      var updated = await pubnub.dataSync
          .updateEntity(id, replace: {'/payload/creditScore': 710});

      var update =
          await nextEvent(queue, eventFor(DataSyncEventType.update, id));
      expect(update.eTag, equals(updated.entity.eTag));
      expect(update.payload!['creditScore'], equals(710));

      await pubnub.dataSync.removeEntity(id);

      var delete =
          await nextEvent(queue, eventFor(DataSyncEventType.delete, id));
      expect(delete.objectType, equals(DataSyncObjectType.entity));
      expect(delete.deletedAt, isNotNull);
      expect(delete.payload, isNull);

      expect(events, everyElement(isA<DataSyncEvent>()));
      expect(events, hasLength(3));
      expect(messages, isEmpty);
    });

    test('emits user create and delete events', () async {
      var (pubnub, cleanup) = testClient();
      var prefix = freshId('dartevt');
      var userId = '$prefix.user';
      var (queue, events, messages) = await listen(pubnub, prefix);

      await pubnub.dataSync.createUser(UserInput(
          classVersion: classVersion, id: userId, payload: {'name': 'U'}));
      cleanup.add(() => pubnub.dataSync.removeUser(userId));

      var create =
          await nextEvent(queue, eventFor(DataSyncEventType.create, userId));
      expect(create.objectType, equals(DataSyncObjectType.user));
      expect(create.className, equals('User'));
      expect(create.payload, equals({'name': 'U'}));

      await pubnub.dataSync.removeUser(userId);

      var delete =
          await nextEvent(queue, eventFor(DataSyncEventType.delete, userId));
      expect(delete.objectType, equals(DataSyncObjectType.user));

      expect(events, everyElement(isA<DataSyncEvent>()));
      expect(messages, isEmpty);
    });

    test('emits channel create and delete events', () async {
      var (pubnub, cleanup) = testClient();
      var prefix = freshId('dartevt');
      var channelId = '$prefix.chan';
      var (queue, events, messages) = await listen(pubnub, prefix);

      await pubnub.dataSync.createChannel(ChannelInput(
          classVersion: classVersion, id: channelId, payload: {'name': 'C'}));
      cleanup.add(() => pubnub.dataSync.removeChannel(channelId));

      var create =
          await nextEvent(queue, eventFor(DataSyncEventType.create, channelId));
      expect(create.objectType, equals(DataSyncObjectType.channel));
      expect(create.className, equals('Channel'));

      await pubnub.dataSync.removeChannel(channelId);

      var delete =
          await nextEvent(queue, eventFor(DataSyncEventType.delete, channelId));
      expect(delete.objectType, equals(DataSyncObjectType.channel));

      expect(events, everyElement(isA<DataSyncEvent>()));
      expect(messages, isEmpty);
    });

    test('emits membership create, update and delete events', () async {
      var (pubnub, cleanup) = testClient();
      var prefix = freshId('dartevt');
      var userId = '$prefix.user';
      var channelId = '$prefix.chan';
      var membershipId = '$prefix.mem';
      await createUser(pubnub, cleanup, userId);
      await createChannel(pubnub, cleanup, channelId);
      var (queue, events, messages) = await listen(pubnub, prefix);

      // Membership events are delivered on both the channel and the user
      // channels — follow the ones on the channel side.
      bool Function(DataSyncEvent) membershipEvent(DataSyncEventType type) =>
          eventFor(type, membershipId, channel: channelId);

      await pubnub.dataSync.createMembership(MembershipInput(
          id: membershipId,
          channelId: channelId,
          userId: userId,
          classVersion: classVersion,
          payload: {'role': 'admin'}));
      cleanup.add(() => pubnub.dataSync.removeMembership(membershipId));

      var create =
          await nextEvent(queue, membershipEvent(DataSyncEventType.create));
      expect(create.objectType, equals(DataSyncObjectType.membership));
      expect(create.className, equals('Membership'));
      expect(create.channelId, equals(channelId));
      expect(create.userId, equals(userId));
      expect(create.payload, equals({'role': 'admin'}));

      await pubnub.dataSync
          .updateMembership(membershipId, replace: {'/payload/role': 'owner'});

      var update =
          await nextEvent(queue, membershipEvent(DataSyncEventType.update));
      expect(update.payload, equals({'role': 'owner'}));

      await pubnub.dataSync.removeMembership(membershipId);

      var delete =
          await nextEvent(queue, membershipEvent(DataSyncEventType.delete));
      expect(delete.objectType, equals(DataSyncObjectType.membership));
      expect(delete.deletedAt, isNotNull);

      expect(events, everyElement(isA<DataSyncEvent>()));
      expect(messages, isEmpty);
    });
  });
}
