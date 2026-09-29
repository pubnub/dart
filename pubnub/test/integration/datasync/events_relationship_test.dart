@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;
  late String id;
  late String customerId;
  late String loanQuoteId;

  setUp(() async {
    pubnub = superClient();
    cleanup = Cleanup();
    id = freshId('dartrequestedby');
    (customerId, loanQuoteId) =
        await seedRelationshipEndpoints(pubnub, cleanup);
  });

  tearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });

  // Relationship events are delivered on the channels of both endpoint
  // entities, never on the relationship id.
  Set<String> endpoints() => {customerId, loanQuoteId};

  void expectCommon(DataSyncEvent event, DataSyncEventType type) =>
      expectEventCommon(event,
          type: type,
          objectType: DataSyncObjectType.relationship,
          id: id,
          channelOneOf: endpoints(),
          className: requestedByClass,
          classLevel: 'SubKey');

  void expectEndpoints(DataSyncEvent event) {
    expect(event.entityAId, equals(customerId));
    expect(event.entityBId, equals(loanQuoteId));
  }

  group('DataSync events [relationship DartREQUESTED_BY]', () {
    test('relationship create emits a create event on the endpoint channels',
        () async {
      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.create, id),
          () =>
              createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId));

      expectCommon(event, DataSyncEventType.create);
      expectEndpoints(event);
      expectEventObjectData(event,
          status: 'active', payload: {'linkedAt': linkedAt});
    });

    test('relationship set (PUT) emits an update event', () async {
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);

      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.setRelationship(
              id,
              RelationshipUpdate(
                  classVersion: classVersion,
                  status: 'active',
                  payload: {'linkedAt': '2026-08-01T00:00:00.000Z'})));

      expectCommon(event, DataSyncEventType.update);
      expectEndpoints(event);
      expectEventObjectData(event,
          payload: {'linkedAt': '2026-08-01T00:00:00.000Z'});
    });

    test('relationship update (PATCH) emits an update event', () async {
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);

      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.updateRelationship(id,
              replace: {'/payload/linkedAt': '2026-09-01T00:00:00.000Z'}));

      expectCommon(event, DataSyncEventType.update);
      expectEndpoints(event);
      expectEventObjectData(event,
          payload: {'linkedAt': '2026-09-01T00:00:00.000Z'});
    });

    test('relationship delete emits a delete event with only id and deletedAt',
        () async {
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);

      var event = await captureEvent(
          pubnub,
          endpoints(),
          eventFor(DataSyncEventType.delete, id),
          () => pubnub.dataSync.removeRelationship(id));

      expectCommon(event, DataSyncEventType.delete);
      expectEventDeleteData(event, id);
    });

    test('a subscriber to the relationship id receives nothing', () async {
      await expectNoEvent(
          pubnub,
          {id},
          () =>
              createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId));
    });
  });
}
