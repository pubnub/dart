import 'objects.dart';

import 'package:pubnub/src/dx/_endpoints/objects/membership.dart';
part 'fixtures/membership.dart';

void main() {
  PubNub pubnub;
  group('DX [objects] [memberships]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'demo', publishKey: 'demo'),
            name: 'default', useAsDefault: true);
    });
    test('getUserMemberships throws when userId is empty', () {
      var userId = '';
      expect(pubnub.memberships.getUserMemberships(userId),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('getUserMemberships  throws if there is no available keyset', () {
      pubnub.keysets.remove('default');
      var userId = 'user-1';
      expect(pubnub.memberships.getUserMemberships(userId),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('getUserMemberships returnes valid response', () async {
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users/user-1/spaces?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getUserMembershipsSuccessResponse);
      var response = await pubnub.memberships.getUserMemberships(userId);

      expect(response, isA<MembershipsResult>());
      expect(response.status, equals(200));
      expect(response.data[0], isA<MembershipInfo>());
    });
    test('getUserMemberships returnes error', () async {
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users/user-1/spaces?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.memberships.getUserMemberships(userId);
      expect(response, isA<MembershipsResult>());
      expect(response.status, 500);
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });

    test('manageUserMemberships throws when userId is empty', () async {
      var userId = '';
      expect(pubnub.memberships.manageUserMemberships(userId),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('manageUserMemberships throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var userId = 'user-1';
      expect(pubnub.memberships.manageUserMemberships(userId),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('manageUserMemberships returnes valid response', () async {
      var userId = 'user-1';
      var add = 'space-1';
      var update = UpdateInfo('space-X', {'expression': 'null'});
      var remove = 'space-2';
      when(
        path:
            'v1/objects/demo/users/user-1/spaces?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _manageUserMembershipsBody,
      ).then(status: 200, body: _manageUserMembershipsSuccessResponse);
      var response = await pubnub.memberships.manageUserMemberships(userId,
          add: <String>{add}, update: [update], remove: <String>{remove});
      expect(response, isA<MembershipsResult>());
      expect(response.status, equals(200));
      expect(response.data[0], isA<MembershipInfo>());
    });
    test('addUserMemberships returnes valid response', () async {
      var userId = 'user-1';
      var add = 'space-1';
      when(
        path:
            'v1/objects/demo/users/user-1/spaces?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _addUserMembershipsBody,
      ).then(status: 200, body: _manageUserMembershipsSuccessResponse);
      var response = await pubnub.memberships.addUserMemberships(userId, [add]);
      expect(response, isA<MembershipsResult>());
      expect(response.status, equals(200));
      expect(response.data[0], isA<MembershipInfo>());
    });

    test('removeUserMemberships returnes valid response', () async {
      var userId = 'user-1';
      var remove = 'space-2';
      when(
        path:
            'v1/objects/demo/users/user-1/spaces?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _removeUserMembershipsBody,
      ).then(status: 200, body: _manageUserMembershipsSuccessResponse);
      var response =
          await pubnub.memberships.removeUserMemberships(userId, [remove]);
      expect(response, isA<MembershipsResult>());
      expect(response.status, equals(200));
      expect(response.data[0], isA<MembershipInfo>());
    });

    test('updateUserMemberships returnes valid response', () async {
      var userId = 'user-1';
      var update = UpdateInfo('space-X', {'expression': 'null'});
      when(
        path:
            'v1/objects/demo/users/user-1/spaces?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _updateUserMembershipsBody,
      ).then(status: 200, body: _manageUserMembershipsSuccessResponse);
      var response =
          await pubnub.memberships.updateUserMemberships(userId, [update]);
      expect(response, isA<MembershipsResult>());
      expect(response.status, equals(200));
      expect(response.data[0], isA<MembershipInfo>());
    });
    test('manageUserMemberships error response', () async {
      var userId = 'user-1';
      var add = 'space-1';
      var update = UpdateInfo('space-X', {'expression': 'null'});
      var remove = 'space-2';
      when(
        path:
            'v1/objects/demo/users/user-1/spaces?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _manageUserMembershipsBody,
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.memberships.manageUserMemberships(userId,
          add: <String>{add}, update: [update], remove: <String>{remove});
      expect(response, isA<MembershipsResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });

    test('getSpaceMembers throws when spaceId is empty', () async {
      var spaceId = '';
      expect(pubnub.memberships.getSpaceMembers(spaceId),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('getSpaceMembers  throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var spaceId = 'space-1';
      expect(pubnub.memberships.getSpaceMembers(spaceId),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('getSpaceMembers returnes valid response', () async {
      var spaceId = 'space-1';
      when(
        path:
            'v1/objects/demo/spaces/space-1/users?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getSpaceMembersSuccessResponse);
      var response = await pubnub.memberships.getSpaceMembers(spaceId);

      expect(response, isA<SpaceMembersResult>());
      expect(response.status, equals(200));
      expect(response.data[0], isA<SpaceMemberInfo>());
    });

    test('getSpaceMembers returnes error response', () async {
      var spaceId = 'space-1';
      when(
        path:
            'v1/objects/demo/spaces/space-1/users?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.memberships.getSpaceMembers(spaceId);
      expect(response, isA<SpaceMembersResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });

    test('manageSpaceMembers throws when spaceId is empty', () async {
      var spaceId = '';
      var add = 'user-1';
      var update = UpdateInfo('user-1', {'address': 'null'});
      var remove = 'user-2';
      expect(
          pubnub.memberships.manageSpaceMembers(spaceId,
              add: <String>{add}, update: [update], remove: <String>{remove}),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('manageSpaceMembers  throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var spaceId = 'space-1';
      var add = 'user-1';
      var update = UpdateInfo('user-1', {'address': 'null'});
      var remove = 'user-2';
      expect(
          pubnub.memberships.manageSpaceMembers(spaceId,
              add: <String>{add}, update: [update], remove: <String>{remove}),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('manageSpaceMembers returnes valid response', () async {
      var spaceId = 'space-1';
      var add = 'user-1';
      var update = UpdateInfo('user-1', {'address': 'null'});
      var remove = 'user-2';
      when(
        path:
            'v1/objects/demo/spaces/space-1/users?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _manageSpaceMembersBody,
      ).then(status: 200, body: _manageSpaceMembersSuccessResponse);
      var response = await pubnub.memberships.manageSpaceMembers(spaceId,
          add: <String>{add}, update: [update], remove: <String>{remove});

      expect(response, isA<SpaceMembersResult>());
      expect(response.status, equals(200));
      expect(response.data[0], isA<SpaceMemberInfo>());
    });
    test('manageSpaceMembers returnes error response', () async {
      var spaceId = 'space-1';
      var add = 'user-1';
      var update = UpdateInfo('user-1', {'address': 'null'});
      var remove = 'user-2';
      when(
        path:
            'v1/objects/demo/spaces/space-1/users?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _manageSpaceMembersBody,
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.memberships.manageSpaceMembers(spaceId,
          add: <String>{add}, update: [update], remove: <String>{remove});
      expect(response, isA<SpaceMembersResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });
  });
}
