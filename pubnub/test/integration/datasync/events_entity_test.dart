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
    id = freshId('dartcustomer');
  });

  tearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });

  void expectCommon(DataSyncEvent event, DataSyncEventType type) =>
      expectEventCommon(event,
          type: type,
          objectType: DataSyncObjectType.entity,
          id: id,
          channelOneOf: {id},
          className: customerClass,
          classLevel: 'SubKey');

  group('DataSync events [entity DartCustomer]', () {
    test('entity create emits a create event', () async {
      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.create, id),
          () => createCustomer(pubnub, cleanup, id));

      expectCommon(event, DataSyncEventType.create);
      expectEventObjectData(event, status: 'active', payload: {
        'customerId': id,
        'firstName': 'Alice',
        'creditScore': 720,
        'city': 'Pune'
      });
      expect(event.expiresAt, isA<String>());
    });

    test('entity set (PUT) emits an update event', () async {
      await createCustomer(pubnub, cleanup, id);

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.setEntity(
              id,
              EntityUpdate(
                  classVersion: classVersion,
                  status: 'updated',
                  payload: customerPayload(id, {'creditScore': 780}))));

      expectCommon(event, DataSyncEventType.update);
      expectEventObjectData(event,
          status: 'updated', payload: {'creditScore': 780});
    });

    test('entity update (PATCH) emits an update event', () async {
      await createCustomer(pubnub, cleanup, id);

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync
              .updateEntity(id, replace: {'/payload/creditScore': 810}));

      expectCommon(event, DataSyncEventType.update);
      expectEventObjectData(event, payload: {'creditScore': 810});
    });

    test('entity delete emits a delete event with only id and deletedAt',
        () async {
      await createCustomer(pubnub, cleanup, id);

      var event = await captureEvent(
          pubnub,
          {id},
          eventFor(DataSyncEventType.delete, id),
          () => pubnub.dataSync.removeEntity(id));

      expectCommon(event, DataSyncEventType.delete);
      expectEventDeleteData(event, id);
    });

    test('DataSync events are not emitted on the messages stream', () async {
      var subscription = pubnub.subscribe(channels: {id});
      var messages = <Envelope>[];
      var listener = subscription.messages.listen(messages.add);
      try {
        await captureEvent(pubnub, {id}, eventFor(DataSyncEventType.create, id),
            () => createCustomer(pubnub, cleanup, id));
        // Give the messages stream the same chance to see the event.
        await Future<void>.delayed(Duration(seconds: 1));
        expect(messages, isEmpty);
      } finally {
        await listener.cancel();
        await subscription.cancel();
      }
    });
  });
}
