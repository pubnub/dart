import 'objects.dart';

import 'package:pubnub/src/dx/_endpoints/objects/user.dart';

part 'fixtures/user.dart';

void main() {
  PubNub pubnub;

  group('DX [objects] [users]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'demo', publishKey: 'demo'),
            name: 'default', useAsDefault: true);
    });
    test('create throws when user object is null', () async {
      expect(pubnub.users.create(null),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('create  throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      expect(pubnub.users.create(usr), throwsA(TypeMatcher<KeysetException>()));
    });

    test('create successfully creates user', () async {
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      when(
        path: 'v1/objects/demo/users?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'POST',
        body: _createuserBody,
      ).then(status: 200, body: _createUserSuccessResponse);
      var response = await pubnub.users.create(usr);

      expect(response, isA<CreateUserResult>());
      expect(response.status, equals(200));
      expect(response.data.id, equals(usr.id));
    });

    test('create user response 400', () async {
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      when(
        path: 'v1/objects/demo/users?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'POST',
        body: _createuserBody,
      ).then(status: 200, body: _httpError400);
      var response = await pubnub.users.create(usr);

      expect(response, isA<CreateUserResult>());
      expect(response.status, equals(400));
    });

    test('create user error response', () async {
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      when(
        path: 'v1/objects/demo/users?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'POST',
        body: _createuserBody,
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.users.create(usr);
      expect(response, isA<CreateUserResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });

    test('getAllUsers should return valid response', () async {
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users?limit=10&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getAllUserSuccessResponse);
      var response = await pubnub.users.getAllUsers(limit: 10);
      expect(response, isA<GetAllUsersResult>());
      expect(response.data[0], isA<UserInfo>());
      expect(response.data[0].id, userId);
    });
    test('getAllUsers sends error response', () async {
      when(
        path:
            'v1/objects/demo/users?limit=10&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.users.getAllUsers(limit: 10);
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });

    test('getAllUsers throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      expect(pubnub.users.getAllUsers(limit: 10),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('getUser should return valid response', () async {
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users/user-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getUserSuccessResponse);
      var response = await pubnub.users.getUser(userId);
      expect(response, isA<GetUserResult>());
      expect(response.data.id, userId);
    });

    test('getUser should return valid response', () async {
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users/user-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.users.getUser(userId);
      expect(response, isA<GetUserResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });

    test('get user throws when userId is empty', () async {
      expect(
          pubnub.users.getUser(''), throwsA(TypeMatcher<InvariantException>()));
    });
    test('getUser throws if there is no available keyset', () async {
      var userId = 'user-1';
      pubnub.keysets.remove('default');
      expect(pubnub.users.getUser(userId),
          throwsA(TypeMatcher<KeysetException>()));
    });
    test('update user throws when userId is empty', () async {
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      expect(pubnub.users.updateUser(usr, ''),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('updateUser throws if there is no available keyset', () async {
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      var userId = 'user-1';
      pubnub.keysets.remove('default');
      expect(pubnub.users.updateUser(usr, userId),
          throwsA(TypeMatcher<KeysetException>()));
    });
    test('update user throws when user object is null', () async {
      expect(pubnub.users.updateUser(null, 'user-1'),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('update user returns valid response', () async {
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users/user-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _updateUserBody,
      ).then(status: 200, body: _updateUserSuccessResponse);
      var response = await pubnub.users.updateUser(usr, userId);
      expect(response, isA<UpdateUserResult>());
      expect(response.status, 200);
      expect(response.data.id, userId);
    });

    test('update user returns error', () async {
      var usr = UserDetails('user-1', 'Name 1', email: 'email@email.com');
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users/user-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _updateUserBody,
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.users.updateUser(usr, userId);
      expect(response, isA<UpdateUserResult>());
      expect(response.status, 500);
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });

    test('delete user throws when userId is empty', () async {
      expect(pubnub.users.deleteUser(''),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('deleteUser throws if there is no available keyset', () async {
      var userId = 'user-1';
      pubnub.keysets.remove('default');
      expect(pubnub.users.deleteUser(userId),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('delete user returns valid response', () async {
      var userId = 'user-1';
      var expectedThen = '{"status": "0","data": {}}';
      when(
        path:
            'v1/objects/demo/users/user-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'DELETE',
      ).then(status: 200, body: expectedThen);
      var response = await pubnub.users.deleteUser(userId);
      expect(response, isA<DeleteUserResult>());
      expect(response.status, '0');
      expect(response.data, {});
    });
    test('delete user returns error', () async {
      var userId = 'user-1';
      when(
        path:
            'v1/objects/demo/users/user-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'DELETE',
      ).then(status: 200, body: _commonObjectError);
      var response = await pubnub.users.deleteUser(userId);
      expect(response, isA<DeleteUserResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });
    test('user() should delegate to users.create()', () async {
      var fakePubnub = FakePubNub();
      var keyset = Keyset(subscribeKey: 'test', publishKey: 'test');
      await fakePubnub.user('user-1', 'name', keyset: keyset);

      var invocation = fakePubnub.invocations[0];

      expect(invocation.isMethod, equals(true));
      expect(invocation.memberName, equals(#user));
      expect(invocation.positionalArguments, equals(['user-1', 'name']));
      expect(
          invocation.namedArguments,
          equals({
            #email: null,
            #custom: null,
            #externalId: null,
            #profileUrl: null,
            #keyset: keyset,
            #using: null
          }));
    });
  });
}
