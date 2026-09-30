@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;
  late String customerId;
  late String loanQuoteId;

  setUp(() async {
    pubnub = superClient();
    cleanup = Cleanup();
    (customerId, loanQuoteId) =
        await seedRelationshipEndpoints(pubnub, cleanup);
  });

  tearDown(() => cleanup.run());

  group('DataSync [relationship] lifecycle', () {
    test('create, get, set, update and remove a DartREQUESTED_BY', () async {
      var id = freshId('dartrequestedby');

      var created =
          await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);
      expect(created.id, equals(id));
      expect(created.entityAId, equals(customerId));
      expect(created.entityBId, equals(loanQuoteId));
      expect(created.relationshipClass, equals(requestedByClass));
      expect(created.relationshipClassVersion, equals(classVersion));
      expect(created.status, equals('active'));
      expect(created.payload, equals({'linkedAt': linkedAt}));
      expect(created.eTag, isNotEmpty);

      var read = (await pubnub.dataSync.getRelationship(id)).relationship;
      expect(read.eTag, equals(created.eTag));

      // The endpoints are immutable, so a full replacement does not carry
      // them.
      var replaced = (await pubnub.dataSync.setRelationship(
              id,
              RelationshipUpdate(
                  classVersion: classVersion,
                  status: 'inactive',
                  payload: {'linkedAt': '2026-08-01T00:00:00.000Z'})))
          .relationship;
      expect(replaced.status, equals('inactive'));
      expect(replaced.entityAId, equals(customerId));
      expect(replaced.entityBId, equals(loanQuoteId));
      expect(replaced.payload!['linkedAt'], equals('2026-08-01T00:00:00.000Z'));
      expect(replaced.eTag, isNot(equals(created.eTag)));

      var patched = (await pubnub.dataSync.updateRelationship(id,
              replace: {'/payload/linkedAt': '2026-09-01T00:00:00.000Z'},
              ifMatchesEtag: replaced.eTag))
          .relationship;
      expect(patched.payload!['linkedAt'], equals('2026-09-01T00:00:00.000Z'));
      expect(patched.entityAId, equals(customerId));

      await pubnub.dataSync.removeRelationship(id, ifMatchesEtag: patched.eTag);
      await expectLater(
          pubnub.dataSync.getRelationship(id), throwsDataSync('DS-0100'));
    });

    test('create without an id returns a server generated id', () async {
      var result = await pubnub.dataSync.createRelationship(RelationshipInput(
          entityAId: customerId,
          entityBId: loanQuoteId,
          className: requestedByClass,
          classVersion: classVersion,
          payload: {'linkedAt': linkedAt}));
      var id = result.relationship.id;
      cleanup.add(() => pubnub.dataSync.removeRelationship(id));

      expect(id, isNotEmpty);
    });

    test('a stale eTag is rejected with DS-0300', () async {
      var id = freshId('dartrequestedby');
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);

      await expectLater(
          pubnub.dataSync.updateRelationship(id,
              replace: {'/payload/linkedAt': linkedAt}, ifMatchesEtag: 'stale'),
          throwsDataSync('DS-0300'));
      await expectLater(
          pubnub.dataSync.removeRelationship(id, ifMatchesEtag: 'stale'),
          throwsDataSync('DS-0300'));
    });
  });

  group('DataSync [relationship] getRelationships', () {
    late String id;

    setUp(() async {
      id = freshId('dartrequestedby');
      await createRequestedBy(pubnub, cleanup, id, customerId, loanQuoteId);
    });

    test('lists by entityAId', () async {
      var result = await pubnub.dataSync
          .getRelationships(requestedByClass, entityAId: customerId);

      expect(result.relationships.map((r) => r.id), equals([id]));
      expect(result.relationships.single.entityAId, equals(customerId));
    });

    test('lists by entityBId', () async {
      var result = await pubnub.dataSync
          .getRelationships(requestedByClass, entityBId: loanQuoteId);

      expect(result.relationships.map((r) => r.id), equals([id]));
    });

    test('lists by both endpoints and the class version', () async {
      var result = await pubnub.dataSync.getRelationships(requestedByClass,
          classVersion: classVersion,
          entityAId: customerId,
          entityBId: loanQuoteId,
          limit: 10);

      expect(result.relationships, hasLength(1));
      expect(result.hasNext, isFalse);
    });

    test('filterFast narrows the listing', () async {
      var result = await pubnub.dataSync.getRelationships(requestedByClass,
          entityAId: customerId, filterFast: "linkedAt == '$linkedAt'");

      expect(result.relationships.map((r) => r.id), equals([id]));
    });
  });

  group('DataSync [relationship] service errors', () {
    test('an endpoint that does not exist is rejected with DS-0100', () async {
      await expectLater(
          pubnub.dataSync.createRelationship(RelationshipInput(
              entityAId: freshId('dartnosuch'),
              entityBId: loanQuoteId,
              className: requestedByClass,
              classVersion: classVersion)),
          throwsDataSync('DS-0100'));
    });

    test('an endpoint of the wrong class is rejected with DS-0800', () async {
      await expectLater(
          pubnub.dataSync.createRelationship(RelationshipInput(
              entityAId: loanQuoteId,
              entityBId: customerId,
              className: requestedByClass,
              classVersion: classVersion)),
          throwsDataSync('DS-0800'));
    });
  });
}
