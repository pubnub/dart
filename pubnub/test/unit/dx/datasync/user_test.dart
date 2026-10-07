import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

const _cursorPage2 = 'eyJpIjoiMzQ5MSIsInN2IjpbXX0';

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = newClient();
  });

  group('DataSync [user] createUser', () {
    test('POST returns a fully formed user, no entityClass sent', () async {
      var payload = userPayload({'department': 'Engineering'});
      when(
        method: 'POST',
        path: dsPath('users'),
        headers: contentType(userContentType),
        body: dataBody({
          'id': 'user-90786',
          'entityClassVersion': 1,
          'status': 'active',
          'payload': payload,
        }),
      ).then(
          status: 200,
          body: dataBody(userObject({'id': 'user-90786', 'payload': payload})));

      var result = await pubnub.dataSync.createUser(UserInput(
          id: 'user-90786',
          classVersion: 1,
          status: 'active',
          payload: payload));

      var user = result.user;
      expect(user.id, equals('user-90786'));
      expect(user.entityClass, equals('User'));
      expect(user.entityClassVersion, equals(1));
      expect(user.entityClassLevel, equals('Global'));
      expect(user.status, equals('active'));
      expect(user.eTag, equals('y2j3ve'));
      expect(user.expiresAt, equals('2026-10-08T00:00:00Z'));
      expect(user.payload, equals(payload));
    });

    test('sends an explicit subclass as entityClass and classLevel', () async {
      when(
        method: 'POST',
        path: dsPath('users'),
        body: dataBody({
          'id': 'user-1',
          'entityClass': 'Employee',
          'entityClassVersion': 1,
          'entityClassLevel': 'SubKey',
          'payload': {'firstName': 'Alice'},
        }),
      ).then(
          status: 200,
          body: dataBody(
              userObject({'id': 'user-1', 'entityClass': 'Employee'})));

      var result = await pubnub.dataSync.createUser(UserInput(
          id: 'user-1',
          className: 'Employee',
          classLevel: ClassLevel.subKey,
          classVersion: 1,
          payload: {'firstName': 'Alice'}));

      expect(result.user.entityClass, equals('Employee'));
    });

    test('sends classLevel Global and omits id when absent', () async {
      when(
        method: 'POST',
        path: dsPath('users'),
        body: dataBody({'entityClassVersion': 1, 'entityClassLevel': 'Global'}),
      ).then(status: 200, body: dataBody(userObject({'id': 'generated-1'})));

      var result = await pubnub.dataSync.createUser(
          UserInput(classVersion: 1, classLevel: ClassLevel.global));

      expect(result.user.id, equals('generated-1'));
    });

    test('surfaces an Access Manager 403 as ForbiddenException', () async {
      when(
              method: 'POST',
              path: dsPath('users'),
              body: dataBody({'entityClassVersion': 1}))
          .then(status: 403, body: body(accessDeniedError));

      await expectLater(pubnub.dataSync.createUser(UserInput(classVersion: 1)),
          throwsA(isA<ForbiddenException>()));
    });
  });

  group('DataSync [user] getUser', () {
    test('GET reads the user back', () async {
      when(method: 'GET', path: dsPath('users', id: 'user-1'))
          .then(status: 200, body: dataBody(userObject({'id': 'user-1'})));

      var result = await pubnub.dataSync.getUser('user-1');

      expect(result.user.id, equals('user-1'));
      expect(result.user.status, equals('active'));
    });

    test('rejects with DataSyncException on 404', () async {
      when(method: 'GET', path: dsPath('users', id: 'user-1'))
          .then(status: 404, body: body(notFoundError('user-1')));

      await expectLater(
          pubnub.dataSync.getUser('user-1'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0100')));
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.getUser(''), throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [user] setUser', () {
    var payload = userPayload({'firstName': 'Bianca', 'department': 'Sales'});

    test('PUT full replace; id in the path, entityClass never in the body',
        () async {
      when(
        method: 'PUT',
        path: dsPath('users', id: 'user-1'),
        headers: contentType(userContentType),
        absentHeaders: {'If-Match'},
        body: dataBody({
          'entityClassVersion': 1,
          'status': 'inactive',
          'payload': payload,
        }),
      ).then(
          status: 200,
          body: dataBody(userObject(
              {'id': 'user-1', 'status': 'inactive', 'payload': payload})));

      var result = await pubnub.dataSync.setUser('user-1',
          UserUpdate(classVersion: 1, status: 'inactive', payload: payload));

      expect(result.user.status, equals('inactive'));
      expect(result.user.payload, equals(payload));
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PUT',
        path: dsPath('users', id: 'user-1'),
        headers: contentType(userContentType, ifMatch: 'y2j3ve'),
        body: dataBody({'entityClassVersion': 1}),
      ).then(status: 200, body: dataBody(userObject({'id': 'user-1'})));

      await pubnub.dataSync.setUser('user-1', UserUpdate(classVersion: 1),
          ifMatchesEtag: 'y2j3ve');
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.setUser('', UserUpdate(classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [user] updateUser', () {
    test('add/replace/remove sends a JSON Patch document', () async {
      when(
        method: 'PATCH',
        path: dsPath('users', id: 'user-1'),
        headers: contentType(patchContentType),
        absentHeaders: {'If-Match'},
        body: body([
          {'op': 'add', 'path': '/payload/phone', 'value': '+15550100'},
          {
            'op': 'replace',
            'path': '/payload/email',
            'value': 'updated@acme.test'
          },
          {'op': 'remove', 'path': '/payload/isActive'},
        ]),
      ).then(status: 200, body: dataBody(userObject({'id': 'user-1'})));

      await pubnub.dataSync.updateUser('user-1',
          add: {'/payload/phone': '+15550100'},
          replace: {'/payload/email': 'updated@acme.test'},
          remove: ['/payload/isActive']);
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PATCH',
        path: dsPath('users', id: 'user-1'),
        headers: contentType(patchContentType, ifMatch: 'y2j3ve'),
        body: body([
          {'op': 'replace', 'path': '/payload/firstName', 'value': 'Amelia'}
        ]),
      ).then(status: 200, body: dataBody(userObject({'id': 'user-1'})));

      await pubnub.dataSync.updateUser('user-1',
          replace: {'/payload/firstName': 'Amelia'}, ifMatchesEtag: 'y2j3ve');
    });

    test('supports move / copy / test ops, emitted after add/replace/remove',
        () async {
      when(
        method: 'PATCH',
        path: dsPath('users', id: 'user-1'),
        headers: contentType(patchContentType),
        body: body([
          {'op': 'remove', 'path': '/payload/obsolete'},
          {
            'op': 'move',
            'from': '/payload/lastName',
            'path': '/payload/surname'
          },
          {
            'op': 'copy',
            'from': '/payload/firstName',
            'path': '/payload/nickname'
          },
          {
            'op': 'test',
            'path': '/payload/email',
            'value': 'alice.verma@acme.test'
          },
        ]),
      ).then(status: 200, body: dataBody(userObject({'id': 'user-1'})));

      await pubnub.dataSync.updateUser('user-1', test: {
        '/payload/email': 'alice.verma@acme.test'
      }, copy: [
        JsonPointerPair(from: '/payload/firstName', path: '/payload/nickname')
      ], move: [
        JsonPointerPair(from: '/payload/lastName', path: '/payload/surname')
      ], remove: [
        '/payload/obsolete'
      ]);
    });

    test('rejects when no operation is provided', () {
      expect(pubnub.dataSync.updateUser('user-1'),
          throwsA(isA<InvariantException>()));
      expect(pubnub.dataSync.updateUser('user-1', move: [], copy: [], test: {}),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [user] removeUser', () {
    test('DELETE replies 200 with an empty body', () async {
      when(
        method: 'DELETE',
        path: dsPath('users', id: 'user-1'),
        absentHeaders: {'If-Match'},
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeUser('user-1');
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'DELETE',
        path: dsPath('users', id: 'user-1'),
        headers: header('If-Match', 'y2j3ve'),
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeUser('user-1', ifMatchesEtag: 'y2j3ve');
    });

    test('rejects an empty id', () {
      expect(
          pubnub.dataSync.removeUser(''), throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [user] getUsers', () {
    var rows = [
      userObject({'id': 'u.1'}),
      userObject({'id': 'u.10'}),
    ];

    test('sends no query parameters beyond the defaults when called bare',
        () async {
      when(method: 'GET', path: dsPath('users'))
          .then(status: 200, body: listBody(rows));

      var result = await pubnub.dataSync.getUsers();

      expect(result.users.map((u) => u.id), equals(['u.1', 'u.10']));
    });

    test('sends limit and surfaces next_cursor', () async {
      when(method: 'GET', path: dsPath('users', query: {'limit': '10'})).then(
          status: 200,
          body: listBody(rows, nextCursor: _cursorPage2, hasNext: true));

      var result = await pubnub.dataSync.getUsers(limit: 10);

      expect(result.hasNext, isTrue);
      expect(result.nextCursor, equals(_cursorPage2));
    });

    test('maps every optional argument to its query parameter', () async {
      when(
        method: 'GET',
        path: dsPath('users', query: {
          'entity_class': 'User',
          'entity_class_version': '1',
          'entity_class_level': 'Global',
          'cursor': _cursorPage2,
          'limit': '50',
          'filter_fast': 'isActive == true',
          'filter': "(department == 'Engineering') AND (location == 'Pune')",
          'sort': '-createdAt',
        }),
      ).then(status: 200, body: listBody(rows));

      await pubnub.dataSync.getUsers(
          className: 'User',
          classVersion: 1,
          classLevel: ClassLevel.global,
          cursor: _cursorPage2,
          limit: 50,
          filterFast: 'isActive == true',
          filter: "(department == 'Engineering') AND (location == 'Pune')",
          sort: '-createdAt');
    });

    test('omits empty string arguments', () async {
      when(method: 'GET', path: dsPath('users'))
          .then(status: 200, body: listBody(rows));

      await pubnub.dataSync
          .getUsers(className: '', cursor: '', filter: '', sort: '');
    });
  });
}
