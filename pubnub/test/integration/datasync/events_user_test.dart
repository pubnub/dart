@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;
  late String id;

  setUp(() {
    pubnub = superClient();
    cleanup = Cleanup();
    id = freshId('dartuser');
  });

  tearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });

  void expectCommon(DataSyncEvent event, DataSyncEventType type) =>
      expectEventCommon(event,
          type: type,
          objectType: DataSyncObjectType.user,
          id: id,
          channelOneOf: {id},
          className: 'User',
          classLevel: 'Global');

  group('DataSync events [user]', () {
    test('user create emits a create event', () async {
      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.create, id),
          () => createUser(pubnub, cleanup, id));

      expectCommon(event, DataSyncEventType.create);
      expectEventObjectData(event,
          status: 'active',
          payload: {'firstName': 'Alice', 'lastName': 'Verma'});
    });

    test('user set (PUT) emits an update event', () async {
      await createUser(pubnub, cleanup, id);

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.setUser(
              id,
              UserUpdate(
                  classVersion: classVersion,
                  status: 'updated',
                  payload: userPayload({'level': 'L4'}))));

      expectCommon(event, DataSyncEventType.update);
      expectEventObjectData(event, status: 'updated', payload: {'level': 'L4'});
    });

    test('user update (PATCH) emits an update event', () async {
      // Replacing a property that does not exist is rejected (DS-0006).
      await createUser(pubnub, cleanup, id, {'level': 'L3'});

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync
              .updateUser(id, replace: {'/payload/level': 'L5'}));

      expectCommon(event, DataSyncEventType.update);
      expectEventObjectData(event, payload: {'level': 'L5'});
    });

    test('user delete emits a delete event with only id and deletedAt',
        () async {
      await createUser(pubnub, cleanup, id);

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.delete, id),
          () => pubnub.dataSync.removeUser(id));

      expectCommon(event, DataSyncEventType.delete);
      expectEventDeleteData(event, id);
    });
  });
}
