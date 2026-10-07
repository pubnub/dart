@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;
  late String id;
  late String userId;
  late String channelId;

  setUp(() async {
    pubnub = superClient();
    cleanup = Cleanup();
    id = freshId('dartmembership');
    userId = freshId('dartuser');
    channelId = freshId('dartchannel');
    await createUser(pubnub, cleanup, userId);
    await createChannel(pubnub, cleanup, channelId);
  });

  tearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });

  // Membership events are delivered on the channel and user channels, never
  // on the membership id.
  Set<String> endpoints() => {channelId, userId};

  void expectCommon(DataSyncEvent event, DataSyncEventType type) =>
      expectEventCommon(event,
          type: type,
          objectType: DataSyncObjectType.membership,
          id: id,
          channelOneOf: endpoints(),
          className: membershipClass,
          classLevel: 'Global');

  void expectEndpoints(DataSyncEvent event) {
    expect(event.channelId, equals(channelId));
    expect(event.userId, equals(userId));
    expect(event.data.containsKey('entityAId'), isFalse);
    expect(event.data.containsKey('entityBId'), isFalse);
  }

  group('DataSync events [membership]', () {
    test('membership create emits a create event on channel and user',
        () async {
      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.create, id),
          () => createMembership(pubnub, cleanup, id, userId, channelId));

      expectCommon(event, DataSyncEventType.create);
      expectEndpoints(event);
      expectEventObjectData(event,
          status: 'active', payload: {'role': 'member'});
    });

    test('membership set (PUT) emits an update event', () async {
      await createMembership(pubnub, cleanup, id, userId, channelId);

      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.setMembership(
              id,
              MembershipUpdate(
                  classVersion: classVersion,
                  status: 'updated',
                  payload: {'role': 'moderator'})));

      expectCommon(event, DataSyncEventType.update);
      expectEndpoints(event);
      expectEventObjectData(event,
          status: 'updated', payload: {'role': 'moderator'});
    });

    test('membership update (PATCH) emits an update event', () async {
      await createMembership(pubnub, cleanup, id, userId, channelId);

      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync
              .updateMembership(id, replace: {'/payload/role': 'admin'}));

      expectCommon(event, DataSyncEventType.update);
      expectEndpoints(event);
      expectEventObjectData(event, payload: {'role': 'admin'});
    });

    test('membership delete emits a delete event with only id and deletedAt',
        () async {
      await createMembership(pubnub, cleanup, id, userId, channelId);

      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.delete, id),
          () => pubnub.dataSync.removeMembership(id));

      expectCommon(event, DataSyncEventType.delete);
      expectEventDeleteData(event, id);
    });

    test('a subscriber to the membership id receives nothing', () async {
      await expectNoEvent(pubnub, {id},
          () => createMembership(pubnub, cleanup, id, userId, channelId));
    });
  });
}
