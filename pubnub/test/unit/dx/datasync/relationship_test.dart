import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

const _cursorPage2 = 'eyJpIjoiNTM4MTQiLCJzdiI6W119';

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = newClient();
  });

  RelationshipInput input(
          {String? id,
          String entityAId = 'customer-20648',
          String entityBId = 'loanquote-23500',
          String className = 'REQUESTED_BY',
          String? status = 'active'}) =>
      RelationshipInput(
          id: id,
          entityAId: entityAId,
          entityBId: entityBId,
          className: className,
          classVersion: 1,
          status: status,
          payload: {'linkedAt': '2026-07-06T10:00:00.000Z'});

  group('DataSync [relationship] createRelationship', () {
    test('POST links two entities', () async {
      when(
        method: 'POST',
        path: dsPath('relationships'),
        headers: contentType(relationshipContentType),
        body: dataBody({
          'id': 'requested-by-55620',
          'entityAId': 'customer-20648',
          'entityBId': 'loanquote-23500',
          'relationshipClass': 'REQUESTED_BY',
          'relationshipClassVersion': 1,
          'status': 'active',
          'payload': {'linkedAt': '2026-07-06T10:00:00.000Z'},
        }),
      ).then(status: 200, body: dataBody(relationshipObject()));

      var result = await pubnub.dataSync
          .createRelationship(input(id: 'requested-by-55620'));

      var relationship = result.relationship;
      expect(relationship.id, equals('requested-by-55620'));
      expect(relationship.entityAId, equals('customer-20648'));
      expect(relationship.entityBId, equals('loanquote-23500'));
      expect(relationship.relationshipClass, equals('REQUESTED_BY'));
      expect(relationship.relationshipClassVersion, equals(1));
      expect(relationship.status, equals('active'));
      expect(relationship.eTag, equals('y3r3fa'));
      expect(relationship.expiresAt, equals('2027-09-08T00:00:00Z'));
      expect(relationship.payload,
          equals({'linkedAt': '2026-07-06T10:00:00.000Z'}));
    });

    test('omits id and status from the body when absent', () async {
      when(
        method: 'POST',
        path: dsPath('relationships'),
        body: dataBody({
          'entityAId': 'customer-20648',
          'entityBId': 'loanquote-23500',
          'relationshipClass': 'REQUESTED_BY',
          'relationshipClassVersion': 1,
          'payload': {'linkedAt': '2026-07-06T10:00:00.000Z'},
        }),
      ).then(
          status: 200,
          body: dataBody(relationshipObject({'id': 'requested-by-61099'})));

      var result =
          await pubnub.dataSync.createRelationship(input(status: null));

      expect(result.relationship.id, equals('requested-by-61099'));
    });

    test('rejects an empty entityAId', () {
      expect(pubnub.dataSync.createRelationship(input(entityAId: '')),
          throwsA(isA<InvariantException>()));
    });

    test('rejects an empty entityBId', () {
      expect(pubnub.dataSync.createRelationship(input(entityBId: '')),
          throwsA(isA<InvariantException>()));
    });

    test('rejects an empty class name', () {
      expect(pubnub.dataSync.createRelationship(input(className: '')),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [relationship] getRelationship', () {
    test('GET reads the relationship back', () async {
      when(method: 'GET', path: dsPath('relationships', id: 'requested-by-1'))
          .then(
              status: 200,
              body: dataBody(relationshipObject({'id': 'requested-by-1'})));

      var result = await pubnub.dataSync.getRelationship('requested-by-1');

      expect(result.relationship.id, equals('requested-by-1'));
      expect(result.relationship.entityAId, equals('customer-20648'));
    });

    test('rejects with DataSyncException on 404', () async {
      when(method: 'GET', path: dsPath('relationships', id: 'requested-by-1'))
          .then(
              status: 404,
              body: body(relationshipNotFoundError('requested-by-1')));

      await expectLater(
          pubnub.dataSync.getRelationship('requested-by-1'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0100')
              .having((e) => e.errorMessage, 'errorMessage',
                  "Relationship 'requested-by-1' not found")));
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.getRelationship(''),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [relationship] setRelationship', () {
    var id = 'requested-by-1';
    var payload = {'linkedAt': '2026-09-01T00:00:00.000Z'};

    test('PUT full replace; body carries no id and no relationshipClass',
        () async {
      when(
        method: 'PUT',
        path: dsPath('relationships', id: id),
        headers: contentType(relationshipContentType),
        absentHeaders: {'If-Match'},
        body: dataBody({
          'relationshipClassVersion': 1,
          'status': 'inactive',
          'payload': payload,
        }),
      ).then(
          status: 200,
          body: dataBody(relationshipObject(
              {'id': id, 'status': 'inactive', 'payload': payload})));

      var result = await pubnub.dataSync.setRelationship(
          id,
          RelationshipUpdate(
              classVersion: 1, status: 'inactive', payload: payload));

      expect(result.relationship.status, equals('inactive'));
      expect(result.relationship.relationshipClass, equals('REQUESTED_BY'));
      expect(result.relationship.payload, equals(payload));
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PUT',
        path: dsPath('relationships', id: id),
        headers: contentType(relationshipContentType, ifMatch: 'y3r3fa'),
        body: dataBody({'relationshipClassVersion': 1}),
      ).then(status: 200, body: dataBody(relationshipObject({'id': id})));

      await pubnub.dataSync.setRelationship(
          id, RelationshipUpdate(classVersion: 1),
          ifMatchesEtag: 'y3r3fa');
    });

    test('rejects an empty id', () {
      expect(
          pubnub.dataSync
              .setRelationship('', RelationshipUpdate(classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [relationship] updateRelationship', () {
    var id = 'requested-by-1';

    test('add/replace/remove sends a JSON Patch document', () async {
      when(
        method: 'PATCH',
        path: dsPath('relationships', id: id),
        headers: contentType(patchContentType),
        absentHeaders: {'If-Match'},
        body: body([
          {'op': 'add', 'path': '/payload/note', 'value': 'renewal'},
          {
            'op': 'replace',
            'path': '/payload/linkedAt',
            'value': '2026-08-01T00:00:00.000Z'
          },
          {'op': 'remove', 'path': '/payload/label'},
        ]),
      ).then(status: 200, body: dataBody(relationshipObject({'id': id})));

      var result = await pubnub.dataSync.updateRelationship(id,
          add: {'/payload/note': 'renewal'},
          replace: {'/payload/linkedAt': '2026-08-01T00:00:00.000Z'},
          remove: ['/payload/label']);

      expect(result.relationship.entityAId, equals('customer-20648'));
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PATCH',
        path: dsPath('relationships', id: id),
        headers: contentType(patchContentType, ifMatch: 'y3r3fa'),
        body: body([
          {'op': 'replace', 'path': '/status', 'value': 'inactive'}
        ]),
      ).then(status: 200, body: dataBody(relationshipObject({'id': id})));

      await pubnub.dataSync.updateRelationship(id,
          replace: {'/status': 'inactive'}, ifMatchesEtag: 'y3r3fa');
    });

    test('supports move / copy / test ops, emitted after add/replace/remove',
        () async {
      when(
        method: 'PATCH',
        path: dsPath('relationships', id: id),
        headers: contentType(patchContentType),
        body: body([
          {'op': 'remove', 'path': '/payload/obsolete'},
          {
            'op': 'move',
            'from': '/payload/label',
            'path': '/payload/labelMoved'
          },
          {
            'op': 'copy',
            'from': '/payload/linkedAt',
            'path': '/payload/linkedAtCopy'
          },
          {
            'op': 'test',
            'path': '/payload/linkedAt',
            'value': '2026-07-06T10:00:00.000Z'
          },
        ]),
      ).then(status: 200, body: dataBody(relationshipObject({'id': id})));

      await pubnub.dataSync.updateRelationship(id, test: {
        '/payload/linkedAt': '2026-07-06T10:00:00.000Z'
      }, copy: [
        JsonPointerPair(
            from: '/payload/linkedAt', path: '/payload/linkedAtCopy')
      ], move: [
        JsonPointerPair(from: '/payload/label', path: '/payload/labelMoved')
      ], remove: [
        '/payload/obsolete'
      ]);
    });

    test('rejects when no operation is provided', () {
      expect(pubnub.dataSync.updateRelationship(id),
          throwsA(isA<InvariantException>()));
      expect(
          pubnub.dataSync.updateRelationship(id, move: [], copy: [], test: {}),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [relationship] removeRelationship', () {
    test('DELETE replies 200 with an empty body', () async {
      when(
        method: 'DELETE',
        path: dsPath('relationships', id: 'requested-by-1'),
        absentHeaders: {'If-Match'},
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeRelationship('requested-by-1');
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'DELETE',
        path: dsPath('relationships', id: 'requested-by-1'),
        headers: header('If-Match', 'y3r3fa'),
      ).then(status: 200, body: '');

      await pubnub.dataSync
          .removeRelationship('requested-by-1', ifMatchesEtag: 'y3r3fa');
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.removeRelationship(''),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [relationship] getRelationships', () {
    var rows = [
      relationshipObject({'id': 'requested-by-1'}),
      relationshipObject({'id': 'requested-by-2'}),
    ];

    test('sends the class as relationship_class', () async {
      when(
        method: 'GET',
        path: dsPath('relationships',
            query: {'relationship_class': 'REQUESTED_BY', 'limit': '50'}),
      ).then(status: 200, body: listBody(rows, limit: 50));

      var result =
          await pubnub.dataSync.getRelationships('REQUESTED_BY', limit: 50);

      expect(result.relationships.map((r) => r.id),
          equals(['requested-by-1', 'requested-by-2']));
      expect(result.page!.limit, equals(50));
      expect(result.hasNext, isFalse);
    });

    test('does not send limit when the caller omits it', () async {
      when(
        method: 'GET',
        path: dsPath('relationships',
            query: {'relationship_class': 'REQUESTED_BY'}),
      ).then(status: 200, body: listBody(rows));

      await pubnub.dataSync.getRelationships('REQUESTED_BY');
    });

    test('sends entityAId and entityBId as entity_a_id and entity_b_id',
        () async {
      when(
        method: 'GET',
        path: dsPath('relationships', query: {
          'relationship_class': 'REQUESTED_BY',
          'relationship_class_version': '1',
          'entity_a_id': 'customer-13775',
          'entity_b_id': 'loanquote-35280',
        }),
      ).then(status: 200, body: listBody([rows.first]));

      var result = await pubnub.dataSync.getRelationships('REQUESTED_BY',
          classVersion: 1,
          entityAId: 'customer-13775',
          entityBId: 'loanquote-35280');

      expect(result.relationships, hasLength(1));
    });

    test('maps cursor, filters and sort to query parameters', () async {
      when(
        method: 'GET',
        path: dsPath('relationships', query: {
          'relationship_class': 'REQUESTED_BY',
          'cursor': _cursorPage2,
          'filter_fast': "linkedAt == '2026-07-06T10:00:00.000Z'",
          'filter':
              "(linkedAt >= '2026-07-01T00:00:00.000Z') AND (label == 'primary')",
          'sort': 'createdAt:desc',
        }),
      ).then(status: 200, body: listBody(rows));

      await pubnub.dataSync.getRelationships('REQUESTED_BY',
          cursor: _cursorPage2,
          filterFast: "linkedAt == '2026-07-06T10:00:00.000Z'",
          filter:
              "(linkedAt >= '2026-07-01T00:00:00.000Z') AND (label == 'primary')",
          sort: 'createdAt:desc');
    });

    test('rejects an empty class name', () {
      expect(pubnub.dataSync.getRelationships(''),
          throwsA(isA<InvariantException>()));
    });
  });
}
