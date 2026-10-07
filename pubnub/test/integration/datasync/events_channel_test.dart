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
    id = freshId('dartchannel');
  });

  tearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });

  void expectCommon(DataSyncEvent event, DataSyncEventType type) =>
      expectEventCommon(event,
          type: type,
          objectType: DataSyncObjectType.channel,
          id: id,
          channelOneOf: {id},
          className: 'Channel',
          classLevel: 'Global');

  group('DataSync events [channel]', () {
    test('channel create emits a create event', () async {
      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.create, id),
          () => createChannel(pubnub, cleanup, id));

      expectCommon(event, DataSyncEventType.create);
      expectEventObjectData(event,
          status: 'active', payload: {'name': 'engineering', 'kind': 'public'});
    });

    test('channel set (PUT) emits an update event', () async {
      await createChannel(pubnub, cleanup, id);

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.setChannel(
              id,
              ChannelUpdate(
                  classVersion: classVersion,
                  status: 'updated',
                  payload: channelPayload({'memberCount': 5}))));

      expectCommon(event, DataSyncEventType.update);
      expectEventObjectData(event,
          status: 'updated', payload: {'memberCount': 5});
    });

    test('channel update (PATCH) emits an update event', () async {
      // Replacing a property that does not exist is rejected (DS-0006).
      await createChannel(pubnub, cleanup, id, {'memberCount': 1});

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync
              .updateChannel(id, replace: {'/payload/memberCount': 9}));

      expectCommon(event, DataSyncEventType.update);
      expectEventObjectData(event, payload: {'memberCount': 9});
    });

    test('channel delete emits a delete event with only id and deletedAt',
        () async {
      await createChannel(pubnub, cleanup, id);

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.delete, id),
          () => pubnub.dataSync.removeChannel(id));

      expectCommon(event, DataSyncEventType.delete);
      expectEventDeleteData(event, id);
    });
  });
}
