@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  // Relationship events are delivered on the channels of both endpoint
  // entities, never on the relationship id.
  void expectRelationshipEvent(DataSyncEvent event, DataSyncEventType type,
      String id, String customerId, String loanQuoteId) {
    expectEventCommon(event,
        type: type,
        objectType: DataSyncObjectType.relationship,
        id: id,
        channelOneOf: {customerId, loanQuoteId},
        className: requestedByClass,
        classLevel: 'SubKey');
  }

  void expectEndpoints(
      DataSyncEvent event, String customerId, String loanQuoteId) {
    expect(event.entityAId, equals(customerId));
    expect(event.entityBId, equals(loanQuoteId));
  }

  group('DataSync events [relationship DartREQUESTED_BY]', () {
    test('relationship create emits a create event on the endpoint channels',
        () async {
      var (pubnub, cleanup) = testClient();
      var id = freshId('dartrequestedby');
      var (customerId, loanQuoteId) =
          await seedRelationshipEndpoints(pubnub, cleanup);

      var event = await captureEvent(
          pubnub,
          {customerId, loanQuoteId},
          eventFor(DataSyncEventType.create, id),
          () =>
              createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId));

      expectRelationshipEvent(
          event, DataSyncEventType.create, id, customerId, loanQuoteId);
      expectEndpoints(event, customerId, loanQuoteId);
      expectEventObjectData(event,
          status: 'active', payload: {'linkedAt': linkedAt});
    });

    test('relationship set (PUT) emits an update event', () async {
      var (pubnub, cleanup) = testClient();
      var id = freshId('dartrequestedby');
      var (customerId, loanQuoteId) =
          await seedRelationshipEndpoints(pubnub, cleanup);
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);

      var event = await captureEvent(
          pubnub,
          {customerId, loanQuoteId},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.setRelationship(
              id,
              RelationshipUpdate(
                  classVersion: classVersion,
                  status: 'active',
                  payload: {'linkedAt': '2026-08-01T00:00:00.000Z'})));

      expectRelationshipEvent(
          event, DataSyncEventType.update, id, customerId, loanQuoteId);
      expectEndpoints(event, customerId, loanQuoteId);
      expectEventObjectData(event,
          payload: {'linkedAt': '2026-08-01T00:00:00.000Z'});
    });

    test('relationship update (PATCH) emits an update event', () async {
      var (pubnub, cleanup) = testClient();
      var id = freshId('dartrequestedby');
      var (customerId, loanQuoteId) =
          await seedRelationshipEndpoints(pubnub, cleanup);
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);

      var event = await captureEvent(
          pubnub,
          {customerId, loanQuoteId},
          eventFor(DataSyncEventType.update, id),
          () => pubnub.dataSync.updateRelationship(id,
              replace: {'/payload/linkedAt': '2026-09-01T00:00:00.000Z'}));

      expectRelationshipEvent(
          event, DataSyncEventType.update, id, customerId, loanQuoteId);
      expectEndpoints(event, customerId, loanQuoteId);
      expectEventObjectData(event,
          payload: {'linkedAt': '2026-09-01T00:00:00.000Z'});
    });

    test('relationship delete emits a delete event with only id and deletedAt',
        () async {
      var (pubnub, cleanup) = testClient();
      var id = freshId('dartrequestedby');
      var (customerId, loanQuoteId) =
          await seedRelationshipEndpoints(pubnub, cleanup);
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);

      var event = await captureEvent(
          pubnub,
          {customerId, loanQuoteId},
          eventFor(DataSyncEventType.delete, id),
          () => pubnub.dataSync.removeRelationship(id));

      expectRelationshipEvent(
          event, DataSyncEventType.delete, id, customerId, loanQuoteId);
      expectEventDeleteData(event, id);
    });

    test('a subscriber to the relationship id receives nothing', () async {
      var (pubnub, cleanup) = testClient();
      var id = freshId('dartrequestedby');
      var (customerId, loanQuoteId) =
          await seedRelationshipEndpoints(pubnub, cleanup);

      await expectNoEvent(
          pubnub,
          {id},
          () =>
              createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId));
    });
  });
}
