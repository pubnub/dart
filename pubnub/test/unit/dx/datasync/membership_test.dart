import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

const _cursorPage2 = 'eyJpIjoiNTM4MDMiLCJzdiI6W119';

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = newClient();
  });

  var payload = {'role': 'member', 'joinedAt': '2026-07-06T10:00:00.000Z'};

  group('DataSync [membership] createMembership', () {
    test('POST associates one user with one channel, class never sent',
        () async {
      when(
        method: 'POST',
        path: dsPath('memberships'),
        headers: contentType(membershipContentType),
        body: dataBody({
          'id': 'membership-18116',
          'channelId': 'JSchannel-46429',
          'userId': 'user-97219',
          'relationshipClassVersion': 1,
          'status': 'active',
          'payload': payload,
        }),
      ).then(status: 200, body: dataBody(membershipObject()));

      var result = await pubnub.dataSync.createMembership(MembershipInput(
          id: 'membership-18116',
          channelId: 'JSchannel-46429',
          userId: 'user-97219',
          classVersion: 1,
          status: 'active',
          payload: payload));

      var membership = result.membership;
      expect(membership.id, equals('membership-18116'));
      expect(membership.channelId, equals('JSchannel-46429'));
      expect(membership.userId, equals('user-97219'));
      expect(membership.relationshipClass, equals('Membership'));
      expect(membership.relationshipClassVersion, equals(1));
      expect(membership.status, equals('active'));
      expect(membership.eTag, equals('y2sto7'));
      expect(membership.expiresAt, equals('2026-10-08T00:00:00Z'));
      expect(membership.payload, equals(payload));
    });

    test('keeps a descendant relationshipClass as sent by the server',
        () async {
      when(
              method: 'POST',
              path: dsPath('memberships'),
              body: dataBody({
                'channelId': 'c',
                'userId': 'u',
                'relationshipClassVersion': 2,
              }))
          .then(
              status: 200,
              body: dataBody(membershipObject({
                'relationshipClass': 'VipMembership',
                'relationshipClassVersion': 2
              })));

      var result = await pubnub.dataSync.createMembership(
          MembershipInput(channelId: 'c', userId: 'u', classVersion: 2));

      expect(result.membership.relationshipClass, equals('VipMembership'));
      expect(result.membership.relationshipClassVersion, equals(2));
    });

    test('rejects an empty userId', () {
      expect(
          pubnub.dataSync.createMembership(
              MembershipInput(channelId: 'c', userId: '', classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });

    test('rejects an empty channelId', () {
      expect(
          pubnub.dataSync.createMembership(
              MembershipInput(channelId: '', userId: 'u', classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [membership] getMembership', () {
    test('GET reads the membership back', () async {
      when(method: 'GET', path: dsPath('memberships', id: 'membership-1')).then(
          status: 200,
          body: dataBody(membershipObject({'id': 'membership-1'})));

      var result = await pubnub.dataSync.getMembership('membership-1');

      expect(result.membership.id, equals('membership-1'));
      expect(result.membership.userId, equals('user-97219'));
    });

    test('rejects with DataSyncException on 404', () async {
      when(method: 'GET', path: dsPath('memberships', id: 'membership-1')).then(
          status: 404, body: body(relationshipNotFoundError('membership-1')));

      await expectLater(
          pubnub.dataSync.getMembership('membership-1'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0100')));
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.getMembership(''),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [membership] setMembership', () {
    test('PUT full replace; no id and no class in the body', () async {
      var newPayload = {'role': 'owner'};
      when(
        method: 'PUT',
        path: dsPath('memberships', id: 'membership-1'),
        headers: contentType(membershipContentType),
        absentHeaders: {'If-Match'},
        body: dataBody({
          'relationshipClassVersion': 2,
          'status': 'inactive',
          'payload': newPayload,
        }),
      ).then(
          status: 200,
          body: dataBody(membershipObject({
            'id': 'membership-1',
            'status': 'inactive',
            'payload': newPayload
          })));

      var result = await pubnub.dataSync.setMembership(
          'membership-1',
          MembershipUpdate(
              classVersion: 2, status: 'inactive', payload: newPayload));

      expect(result.membership.status, equals('inactive'));
      expect(result.membership.payload, equals(newPayload));
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PUT',
        path: dsPath('memberships', id: 'membership-1'),
        headers: contentType(membershipContentType, ifMatch: 'y2sto7'),
        body: dataBody({'relationshipClassVersion': 1}),
      ).then(
          status: 200,
          body: dataBody(membershipObject({'id': 'membership-1'})));

      await pubnub.dataSync.setMembership(
          'membership-1', MembershipUpdate(classVersion: 1),
          ifMatchesEtag: 'y2sto7');
    });

    test('rejects an empty id', () {
      expect(
          pubnub.dataSync.setMembership('', MembershipUpdate(classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [membership] updateMembership', () {
    test('add/replace/remove sends a JSON Patch document', () async {
      when(
        method: 'PATCH',
        path: dsPath('memberships', id: 'membership-1'),
        headers: contentType(patchContentType),
        absentHeaders: {'If-Match'},
        body: body([
          {
            'op': 'add',
            'path': '/payload/lastReadAt',
            'value': '2026-08-01T00:00:00.000Z'
          },
          {'op': 'replace', 'path': '/payload/role', 'value': 'moderator'},
          {'op': 'remove', 'path': '/payload/notificationsEnabled'},
        ]),
      ).then(
          status: 200,
          body: dataBody(membershipObject({'id': 'membership-1'})));

      await pubnub.dataSync.updateMembership('membership-1',
          add: {'/payload/lastReadAt': '2026-08-01T00:00:00.000Z'},
          replace: {'/payload/role': 'moderator'},
          remove: ['/payload/notificationsEnabled']);
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PATCH',
        path: dsPath('memberships', id: 'membership-1'),
        headers: contentType(patchContentType, ifMatch: 'y2sto7'),
        body: body([
          {'op': 'replace', 'path': '/status', 'value': 'inactive'}
        ]),
      ).then(
          status: 200,
          body: dataBody(membershipObject({'id': 'membership-1'})));

      await pubnub.dataSync.updateMembership('membership-1',
          replace: {'/status': 'inactive'}, ifMatchesEtag: 'y2sto7');
    });

    test('supports move / copy / test ops, emitted after add/replace/remove',
        () async {
      when(
        method: 'PATCH',
        path: dsPath('memberships', id: 'membership-1'),
        headers: contentType(patchContentType),
        body: body([
          {'op': 'remove', 'path': '/payload/obsolete'},
          {
            'op': 'move',
            'from': '/payload/joinedAt',
            'path': '/payload/joinedAtMoved'
          },
          {'op': 'copy', 'from': '/payload/role', 'path': '/payload/roleCopy'},
          {'op': 'test', 'path': '/payload/role', 'value': 'member'},
        ]),
      ).then(
          status: 200,
          body: dataBody(membershipObject({'id': 'membership-1'})));

      await pubnub.dataSync.updateMembership('membership-1', test: {
        '/payload/role': 'member'
      }, copy: [
        JsonPointerPair(from: '/payload/role', path: '/payload/roleCopy')
      ], move: [
        JsonPointerPair(
            from: '/payload/joinedAt', path: '/payload/joinedAtMoved')
      ], remove: [
        '/payload/obsolete'
      ]);
    });

    test('rejects when no operation is provided', () {
      expect(pubnub.dataSync.updateMembership('membership-1'),
          throwsA(isA<InvariantException>()));
      expect(
          pubnub.dataSync
              .updateMembership('membership-1', move: [], copy: [], test: {}),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [membership] removeMembership', () {
    test('DELETE replies 200 with an empty body', () async {
      when(
        method: 'DELETE',
        path: dsPath('memberships', id: 'membership-1'),
        absentHeaders: {'If-Match'},
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeMembership('membership-1');
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'DELETE',
        path: dsPath('memberships', id: 'membership-1'),
        headers: header('If-Match', 'y2sto7'),
      ).then(status: 200, body: '');

      await pubnub.dataSync
          .removeMembership('membership-1', ifMatchesEtag: 'y2sto7');
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.removeMembership(''),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [membership] getMemberships', () {
    var rows = [
      membershipObject({'id': 'membership-1'}),
      membershipObject({
        'id': 'membership-2',
        'relationshipClass': 'VipMembership',
        'relationshipClassVersion': 2
      }),
    ];

    test('sends no query parameters beyond the defaults when called bare',
        () async {
      when(method: 'GET', path: dsPath('memberships'))
          .then(status: 200, body: listBody(rows));

      var result = await pubnub.dataSync.getMemberships();

      expect(
          result.memberships
              .map((m) => [m.relationshipClass, m.relationshipClassVersion]),
          equals([
            ['Membership', 1],
            ['VipMembership', 2]
          ]));
    });

    test('maps every optional argument to its query parameter', () async {
      when(
        method: 'GET',
        path: dsPath('memberships', query: {
          'user_id': 'user-97219',
          'channel_id': 'JSchannel-46429',
          'relationship_class_version': '1',
          'cursor': _cursorPage2,
          'limit': '25',
          'filter_fast': "role == 'admin'",
          'filter': "(role == 'admin') AND (notificationsEnabled == true)",
          'sort': 'createdAt:desc',
        }),
      ).then(status: 200, body: listBody([rows.first]));

      var result = await pubnub.dataSync.getMemberships(
          userId: 'user-97219',
          channelId: 'JSchannel-46429',
          classVersion: 1,
          cursor: _cursorPage2,
          limit: 25,
          filterFast: "role == 'admin'",
          filter: "(role == 'admin') AND (notificationsEnabled == true)",
          sort: 'createdAt:desc');

      expect(result.memberships, hasLength(1));
    });

    test('sends userId alone as user_id', () async {
      when(
        method: 'GET',
        path: dsPath('memberships', query: {'user_id': 'user-97219'}),
      ).then(status: 200, body: listBody(rows));

      await pubnub.dataSync.getMemberships(userId: 'user-97219');
    });
  });
}
