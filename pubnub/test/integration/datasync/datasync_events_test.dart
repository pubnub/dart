@TestOn('vm')
@Tags(['integration'])

import 'dart:math';

import 'package:async/async.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

/// Changes DataSync objects on the live server and verifies that the
/// real-time events are emitted on [Subscription.dataSync] only.
void main() {
  late PubNub pubnub;
  late String prefix;
  late Subscription subscription;
  late List<SubscriptionEvent> events;
  late List<Envelope> messages;

  late Cleanup cleanup;

  setUp(() async {
    prefix = 'dartevt${10000 + Random().nextInt(90000)}';
    events = [];
    messages = [];
    cleanup = Cleanup();

    pubnub = superClient(userId: 'dart-datasync-events-test');

    // Events of an object are delivered on the channel named after its id, so
    // a wildcard over the id prefix receives all of them.
    subscription = pubnub.subscribe(channels: {'$prefix.*'});
    subscription.events.listen(events.add);
    subscription.messages.listen(messages.add);
    await subscription.whenStarts;
    // The create event can only be seen once the long poll is established.
    await Future<void>.delayed(Duration(seconds: 3));
  });

  tearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });

  group('Subscription dataSync stream', () {
    test('emits entity create, update and delete events', () async {
      var id = '$prefix.customer';
      var queue = StreamQueue(subscription.dataSync);

      var payload = customerPayload(id, {'creditScore': 700});
      var created = await pubnub.dataSync.createEntity(EntityInput(
          id: id,
          className: customerClass,
          classVersion: classVersion,
          payload: payload));
      cleanup.add(() => pubnub.dataSync.removeEntity(id));

      var create = await queue.next.timeout(eventTimeout);
      expect(create.event, equals(DataSyncEventType.create));
      expect(create.objectType, equals(DataSyncObjectType.entity));
      expect(create.id, equals(id));
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

      var update = await queue.next.timeout(eventTimeout);
      expect(update.event, equals(DataSyncEventType.update));
      expect(update.id, equals(id));
      expect(update.eTag, equals(updated.entity.eTag));
      expect(update.payload!['creditScore'], equals(710));

      await pubnub.dataSync.removeEntity(id);

      var delete = await queue.next.timeout(eventTimeout);
      expect(delete.event, equals(DataSyncEventType.delete));
      expect(delete.objectType, equals(DataSyncObjectType.entity));
      expect(delete.id, equals(id));
      expect(delete.deletedAt, isNotNull);
      expect(delete.payload, isNull);

      expect(events, everyElement(isA<DataSyncEvent>()));
      expect(events, hasLength(3));
      expect(messages, isEmpty);

      await queue.cancel();
    });

    test('emits user, channel and membership events', () async {
      var userId = '$prefix.user';
      var channelId = '$prefix.chan';
      var membershipId = '$prefix.mem';

      // Membership events are delivered on both the channel and the user
      // channels — follow the ones on the channel side.
      var queue = StreamQueue(subscription.dataSync.where((event) =>
          event.objectType != DataSyncObjectType.membership ||
          event.channel == channelId));

      await pubnub.dataSync.createUser(UserInput(
          classVersion: classVersion, id: userId, payload: {'name': 'U'}));
      cleanup.add(() => pubnub.dataSync.removeUser(userId));

      var userCreate = await queue.next.timeout(eventTimeout);
      expect(userCreate.event, equals(DataSyncEventType.create));
      expect(userCreate.objectType, equals(DataSyncObjectType.user));
      expect(userCreate.id, equals(userId));
      expect(userCreate.className, equals('User'));
      expect(userCreate.payload, equals({'name': 'U'}));

      await pubnub.dataSync.createChannel(ChannelInput(
          classVersion: classVersion, id: channelId, payload: {'name': 'C'}));
      cleanup.add(() => pubnub.dataSync.removeChannel(channelId));

      var channelCreate = await queue.next.timeout(eventTimeout);
      expect(channelCreate.event, equals(DataSyncEventType.create));
      expect(channelCreate.objectType, equals(DataSyncObjectType.channel));
      expect(channelCreate.id, equals(channelId));
      expect(channelCreate.className, equals('Channel'));

      await pubnub.dataSync.createMembership(MembershipInput(
          id: membershipId,
          channelId: channelId,
          userId: userId,
          classVersion: classVersion,
          payload: {'role': 'admin'}));
      cleanup.add(() => pubnub.dataSync.removeMembership(membershipId));

      var membershipCreate = await queue.next.timeout(eventTimeout);
      expect(membershipCreate.event, equals(DataSyncEventType.create));
      expect(
          membershipCreate.objectType, equals(DataSyncObjectType.membership));
      expect(membershipCreate.id, equals(membershipId));
      expect(membershipCreate.className, equals('Membership'));
      expect(membershipCreate.channelId, equals(channelId));
      expect(membershipCreate.userId, equals(userId));
      expect(membershipCreate.payload, equals({'role': 'admin'}));

      await pubnub.dataSync
          .updateMembership(membershipId, replace: {'/payload/role': 'owner'});

      var membershipUpdate = await queue.next.timeout(eventTimeout);
      expect(membershipUpdate.event, equals(DataSyncEventType.update));
      expect(membershipUpdate.id, equals(membershipId));
      expect(membershipUpdate.payload, equals({'role': 'owner'}));

      await pubnub.dataSync.removeMembership(membershipId);

      var membershipDelete = await queue.next.timeout(eventTimeout);
      expect(membershipDelete.event, equals(DataSyncEventType.delete));
      expect(membershipDelete.id, equals(membershipId));
      expect(membershipDelete.deletedAt, isNotNull);

      await pubnub.dataSync.removeChannel(channelId);

      var channelDelete = await queue.next.timeout(eventTimeout);
      expect(channelDelete.event, equals(DataSyncEventType.delete));
      expect(channelDelete.objectType, equals(DataSyncObjectType.channel));
      expect(channelDelete.id, equals(channelId));

      await pubnub.dataSync.removeUser(userId);

      var userDelete = await queue.next.timeout(eventTimeout);
      expect(userDelete.event, equals(DataSyncEventType.delete));
      expect(userDelete.objectType, equals(DataSyncObjectType.user));
      expect(userDelete.id, equals(userId));

      expect(events, everyElement(isA<DataSyncEvent>()));
      expect(messages, isEmpty);

      await queue.cancel();
    });
  });
}
