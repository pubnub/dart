import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = newClient();
  });

  group('DataSync [entity] createEntity', () {
    test('POST returns a fully formed entity', () async {
      var id = 'customer-43508';
      when(
        method: 'POST',
        path: dsPath('entities'),
        headers: contentType(entityContentType),
        body: dataBody({
          'id': id,
          'entityClass': 'Customer',
          'entityClassVersion': 1,
          'status': 'active',
          'payload': customerPayload(id),
        }),
      ).then(status: 200, body: dataBody(entityObject()));

      var result = await pubnub.dataSync.createEntity(EntityInput(
          id: id,
          className: 'Customer',
          classVersion: 1,
          status: 'active',
          payload: customerPayload(id)));

      var entity = result.entity;
      expect(entity.id, equals(id));
      expect(entity.entityClass, equals('Customer'));
      expect(entity.entityClassVersion, equals(1));
      expect(entity.entityClassLevel, equals('SubKey'));
      expect(entity.status, equals('active'));
      expect(entity.payload, equals(customerPayload(id)));
      expect(entity.eTag, equals('y26s8e'));
      expect(entity.createdAt, equals('2026-09-07T07:25:20.309207Z'));
      expect(entity.updatedAt, equals('2026-09-07T07:25:20.309207Z'));
      expect(entity.expiresAt, equals('2027-09-08T00:00:00Z'));
    });

    test('omits id when absent and returns the server generated id', () async {
      var generatedId = 'e3d1f0c2-8b64-4a1e-9f2c-5d7a6b9c0e11';
      when(
        method: 'POST',
        path: dsPath('entities'),
        body: dataBody({
          'entityClass': 'Customer',
          'entityClassVersion': 1,
          'payload': {'customerId': 'anonymous'},
        }),
      ).then(status: 200, body: dataBody(entityObject({'id': generatedId})));

      var result = await pubnub.dataSync.createEntity(EntityInput(
          className: 'Customer',
          classVersion: 1,
          payload: {'customerId': 'anonymous'}));

      expect(result.entity.id, equals(generatedId));
    });

    for (var level in ClassLevel.values) {
      test('sends classLevel ${level.name} as entityClassLevel', () async {
        when(
          method: 'POST',
          path: dsPath('entities'),
          body: dataBody({
            'id': 'entity-1',
            'entityClass': 'Customer',
            'entityClassVersion': 1,
            'entityClassLevel':
                level == ClassLevel.global ? 'Global' : 'SubKey',
            'status': 'active',
            'payload': {'name': 'Alice'},
          }),
        ).then(status: 200, body: dataBody(entityObject()));

        await pubnub.dataSync.createEntity(EntityInput(
            id: 'entity-1',
            className: 'Customer',
            classVersion: 1,
            classLevel: level,
            status: 'active',
            payload: {'name': 'Alice'}));
      });
    }

    test('rejects an empty class name', () {
      expect(
          pubnub.dataSync
              .createEntity(EntityInput(className: '', classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [entity] getEntity', () {
    test('GET reads the entity back', () async {
      when(method: 'GET', path: dsPath('entities', id: 'customer-16321')).then(
          status: 200, body: dataBody(entityObject({'id': 'customer-16321'})));

      var result = await pubnub.dataSync.getEntity('customer-16321');

      expect(result.entity.id, equals('customer-16321'));
      expect(result.entity.payload, equals(customerPayload('customer-16321')));
    });

    test('percent encodes the id path segment', () async {
      when(method: 'GET', path: dsPath('entities', id: 'a b/c'))
          .then(status: 200, body: dataBody(entityObject({'id': 'a b/c'})));

      var result = await pubnub.dataSync.getEntity('a b/c');

      expect(result.entity.id, equals('a b/c'));
    });

    test('rejects with DataSyncException on 404', () async {
      when(method: 'GET', path: dsPath('entities', id: 'customer-33238'))
          .then(status: 404, body: body(notFoundError('customer-33238')));

      await expectLater(
          pubnub.dataSync.getEntity('customer-33238'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0100')
              .having((e) => e.errorMessage, 'errorMessage',
                  'Entity not found: customer-33238')
              .having((e) => e.errors.length, 'errors.length', 1)));
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.getEntity(''), throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [entity] setEntity', () {
    var id = 'customer-70652';
    var payload = customerPayload(id, {'creditScore': 600, 'city': 'Mumbai'});

    test('PUT full replace; id in the path, entityClass never in the body',
        () async {
      when(
        method: 'PUT',
        path: dsPath('entities', id: id),
        headers: contentType(entityContentType),
        absentHeaders: {'If-Match'},
        body: dataBody({
          'entityClassVersion': 1,
          'status': 'inactive',
          'payload': payload,
        }),
      ).then(
          status: 200,
          body: dataBody(entityObject(
              {'id': id, 'status': 'inactive', 'payload': payload})));

      var result = await pubnub.dataSync.setEntity(id,
          EntityUpdate(classVersion: 1, status: 'inactive', payload: payload));

      expect(result.entity.id, equals(id));
      expect(result.entity.status, equals('inactive'));
      expect(result.entity.entityClass, equals('Customer'));
      expect(result.entity.payload, equals(payload));
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PUT',
        path: dsPath('entities', id: id),
        headers: contentType(entityContentType, ifMatch: 'y26tel'),
        body: dataBody({'entityClassVersion': 1}),
      ).then(status: 200, body: dataBody(entityObject({'id': id})));

      await pubnub.dataSync.setEntity(id, EntityUpdate(classVersion: 1),
          ifMatchesEtag: 'y26tel');
    });

    // Regression for B3: an empty eTag is sent as an empty `If-Match` header.
    test('does not send an empty If-Match header', () async {
      when(
        method: 'PUT',
        path: dsPath('entities', id: id),
        absentHeaders: {'If-Match'},
        body: dataBody({'entityClassVersion': 1}),
      ).then(status: 200, body: dataBody(entityObject({'id': id})));

      await pubnub.dataSync
          .setEntity(id, EntityUpdate(classVersion: 1), ifMatchesEtag: '');
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.setEntity('', EntityUpdate(classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [entity] updateEntity', () {
    var id = 'customer-16321';

    test('add/replace/remove sends a JSON Patch document in a stable order',
        () async {
      when(
        method: 'PATCH',
        path: dsPath('entities', id: id),
        headers: contentType(patchContentType),
        absentHeaders: {'If-Match'},
        body: body([
          {'op': 'add', 'path': '/payload/phone', 'value': '+15550100'},
          {'op': 'replace', 'path': '/payload/creditScore', 'value': 810},
          {'op': 'remove', 'path': '/payload/city'},
        ]),
      ).then(
          status: 200,
          body: dataBody(entityObject({
            'id': id,
            'eTag': 'y26ue7',
            'payload': customerPayload(id, {'creditScore': 810})
              ..remove('city')
              ..['phone'] = '+15550100',
          })));

      var result = await pubnub.dataSync.updateEntity(id,
          remove: ['/payload/city'],
          replace: {'/payload/creditScore': 810},
          add: {'/payload/phone': '+15550100'});

      expect(result.entity.payload!['creditScore'], equals(810));
      expect(result.entity.payload!['phone'], equals('+15550100'));
      expect(result.entity.payload!.containsKey('city'), isFalse);
      expect(result.entity.eTag, equals('y26ue7'));
    });

    test('passes paths through verbatim and keeps map insertion order',
        () async {
      when(
        method: 'PATCH',
        path: dsPath('entities', id: id),
        body: body([
          {'op': 'replace', 'path': '/payload/lastName', 'value': 'Rao'},
          {'op': 'replace', 'path': '/payload/address.city', 'value': 'Goa'},
          {'op': 'replace', 'path': '/status', 'value': 'inactive'},
        ]),
      ).then(status: 200, body: dataBody(entityObject({'id': id})));

      await pubnub.dataSync.updateEntity(id, replace: {
        '/payload/lastName': 'Rao',
        '/payload/address.city': 'Goa',
        '/status': 'inactive',
      });
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PATCH',
        path: dsPath('entities', id: id),
        headers: contentType(patchContentType, ifMatch: 'y26tel'),
        body: body([
          {'op': 'replace', 'path': '/payload/creditScore', 'value': 700}
        ]),
      ).then(status: 200, body: dataBody(entityObject({'id': id})));

      await pubnub.dataSync.updateEntity(id,
          replace: {'/payload/creditScore': 700}, ifMatchesEtag: 'y26tel');
    });

    test('supports move / copy / test ops, emitted after add/replace/remove',
        () async {
      when(
        method: 'PATCH',
        path: dsPath('entities', id: id),
        headers: contentType(patchContentType),
        body: body([
          {'op': 'remove', 'path': '/payload/obsolete'},
          {
            'op': 'move',
            'from': '/payload/creditScore',
            'path': '/payload/score'
          },
          {
            'op': 'copy',
            'from': '/payload/firstName',
            'path': '/payload/firstNameCopy'
          },
          {'op': 'test', 'path': '/payload/firstName', 'value': 'Alice'},
        ]),
      ).then(status: 200, body: dataBody(entityObject({'id': id})));

      await pubnub.dataSync.updateEntity(id, test: {
        '/payload/firstName': 'Alice'
      }, copy: [
        JsonPointerPair(
            from: '/payload/firstName', path: '/payload/firstNameCopy')
      ], move: [
        JsonPointerPair(from: '/payload/creditScore', path: '/payload/score')
      ], remove: [
        '/payload/obsolete'
      ]);
    });

    test('rejects when no operation is provided', () {
      expect(
          pubnub.dataSync.updateEntity(id), throwsA(isA<InvariantException>()));
      expect(pubnub.dataSync.updateEntity(id, add: {}, replace: {}, remove: []),
          throwsA(isA<InvariantException>()));
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.updateEntity('', add: {'/payload/a': 1}),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [entity] removeEntity', () {
    test('DELETE replies 200 with an empty body', () async {
      when(
        method: 'DELETE',
        path: dsPath('entities', id: 'customer-1'),
        absentHeaders: {'If-Match'},
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeEntity('customer-1');
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'DELETE',
        path: dsPath('entities', id: 'customer-1'),
        headers: header('If-Match', 'y26tel'),
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeEntity('customer-1', ifMatchesEtag: 'y26tel');
    });

    test('rejects an empty id', () {
      expect(
          pubnub.dataSync.removeEntity(''), throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [entity] getEntities', () {
    var page1 = [
      entityObject({'id': 'customer.001'}),
      entityObject({'id': 'customer.002'}),
    ];
    var page2 = [
      entityObject({'id': 'customer.004', 'status': 'active-normal'}),
      entityObject({'id': 'customer.005'}),
    ];

    test('sends entity_class plus limit and returns the list envelope',
        () async {
      when(
        method: 'GET',
        path: dsPath('entities',
            query: {'entity_class': 'Customer', 'limit': '50'}),
      ).then(status: 200, body: listBody(page1, limit: 50));

      var result = await pubnub.dataSync.getEntities('Customer', limit: 50);

      expect(result.entities.map((e) => e.id),
          equals(['customer.001', 'customer.002']));
      expect(result.entities.every((e) => e.entityClass == 'Customer'), isTrue);
      expect(result.page!.limit, equals(50));
      expect(result.hasNext, isFalse);
      expect(result.nextCursor, isNull);
    });

    test('does not send limit when the caller omits it', () async {
      when(
        method: 'GET',
        path: dsPath('entities', query: {'entity_class': 'Customer'}),
      ).then(status: 200, body: listBody(page1));

      await pubnub.dataSync.getEntities('Customer');
    });

    test('threads next_cursor into the following request', () async {
      when(
        method: 'GET',
        path: dsPath('entities',
            query: {'entity_class': 'Customer', 'limit': '2'}),
      ).then(
          status: 200,
          body: listBody(page1,
              nextCursor: entityCursorPage2, hasNext: true, limit: 2));
      when(
        method: 'GET',
        path: dsPath('entities', query: {
          'entity_class': 'Customer',
          'limit': '2',
          'cursor': entityCursorPage2
        }),
      ).then(
          status: 200,
          body: listBody(page2,
              nextCursor: entityCursorPage3, hasNext: true, limit: 2));

      var first = await pubnub.dataSync.getEntities('Customer', limit: 2);
      expect(first.entities, hasLength(2));
      expect(first.hasNext, isTrue);
      expect(first.nextCursor, equals(entityCursorPage2));

      var second = await pubnub.dataSync
          .getEntities('Customer', limit: 2, cursor: first.nextCursor);
      expect(second.nextCursor, equals(entityCursorPage3));

      var firstIds = first.entities.map((e) => e.id).toSet();
      expect(second.entities.where((e) => firstIds.contains(e.id)), isEmpty);
    });

    test('maps every optional argument to its query parameter', () async {
      when(
        method: 'GET',
        path: dsPath('entities', query: {
          'entity_class': 'Customer',
          'entity_class_version': '1',
          'entity_class_level': 'SubKey',
          'cursor': entityCursorPage2,
          'limit': '100',
          'filter_fast': "city == 'Pune'",
          'filter': "creditScore >= 700 && city == 'Pune'",
          'sort': 'firstName:desc',
        }),
      ).then(status: 200, body: listBody(page1));

      await pubnub.dataSync.getEntities('Customer',
          classVersion: 1,
          classLevel: ClassLevel.subKey,
          cursor: entityCursorPage2,
          limit: 100,
          filterFast: "city == 'Pune'",
          filter: "creditScore >= 700 && city == 'Pune'",
          sort: 'firstName:desc');
    });

    test('passes a raw string sort through unchanged', () async {
      when(
        method: 'GET',
        path: dsPath('entities',
            query: {'entity_class': 'Customer', 'sort': '-createdAt'}),
      ).then(status: 200, body: listBody(page1));

      await pubnub.dataSync.getEntities('Customer', sort: '-createdAt');
    });

    test('omits empty string arguments', () async {
      when(
        method: 'GET',
        path: dsPath('entities', query: {'entity_class': 'Customer'}),
      ).then(status: 200, body: listBody(page1));

      await pubnub.dataSync.getEntities('Customer',
          cursor: '', filterFast: '', filter: '', sort: '');
    });

    test('rejects an empty class name', () {
      expect(
          pubnub.dataSync.getEntities(''), throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [entity] keyset', () {
    test('adds auth when the keyset has an auth key', () async {
      pubnub = newClient(authKey: 'myAuth');
      when(
        method: 'GET',
        path: dsPath('entities', id: 'customer-1', query: {'auth': 'myAuth'}),
      ).then(status: 200, body: dataBody(entityObject({'id': 'customer-1'})));

      await pubnub.dataSync.getEntity('customer-1');
    });

    test('uses the subscribe key of the named keyset', () async {
      pubnub.keysets.add(
          'other',
          Keyset(
              subscribeKey: 'other-sub',
              publishKey: 'other-pub',
              userId: UserId('other')));
      when(
        method: 'GET',
        path: dsPath('entities',
            id: 'customer-1', subscribeKey: 'other-sub', uuid: 'other'),
      ).then(status: 200, body: dataBody(entityObject({'id': 'customer-1'})));

      await pubnub.dataSync.getEntity('customer-1', using: 'other');
    });
  });
}
