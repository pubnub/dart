import 'objects.dart';

import 'package:pubnub/src/dx/_endpoints/objects/space.dart';

part 'fixtures/space.dart';

void main() {
  PubNub pubnub;
  group('[spaces]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'demo', publishKey: 'demo'),
            name: 'default', useAsDefault: true);
    });

    test('create throws when space object is null', () async {
      expect(pubnub.spaces.create(null),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('create space successfully creates space', () async {
      var space = SpaceDetails('my-channel', 'My space',
          description: 'A space that is mine');
      when(
          path: 'v1/objects/demo/spaces',
          method: 'POST',
          body: _createSpaceBody,
          then: FakeResult(_createSpaceSuccessResponse));
      var response = await pubnub.spaces.create(space);

      expect(response, isA<CreateSpaceResult>());
      expect(response.status, equals(200));
      expect(response.data.id, equals(space.id));
    });
    test('create space response with http 400', () async {
      var space = SpaceDetails('my-channel', 'My space',
          description: 'A space that is mine');
      when(
          path: 'v1/objects/demo/spaces',
          method: 'POST',
          body: _createSpaceBody,
          then: FakeResult(_httpError400));
      var response = await pubnub.spaces.create(space);

      expect(response, isA<CreateSpaceResult>());
      expect(response.status, equals(400));
    });

    test('create space error response', () async {
      var space = SpaceDetails('my-channel', 'My space',
          description: 'A space that is mine');
      when(
          path: 'v1/objects/demo/spaces',
          method: 'POST',
          body: _createSpaceBody,
          then: FakeResult(_commonObjectError));
      var response = await pubnub.spaces.create(space);
      expect(response, isA<CreateSpaceResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });
    test('create space throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var space = SpaceDetails('my-channel', 'My space',
          description: 'A space that is mine');
      expect(
          pubnub.spaces.create(space), throwsA(TypeMatcher<KeysetException>()));
    });

    test('getAllSpaces should return valid response', () async {
      var id = 'my-channel';
      when(
          path: 'v1/objects/demo/spaces?limit=10',
          method: 'GET',
          then: FakeResult(_getAllSpacesSuccessResponse));
      var response = await pubnub.spaces.getAllSpaces(limit: 10);
      expect(response.status, 200);
      expect(response, isA<GetAllSpacesResult>());
      expect(response.data[0], isA<SpaceInfo>());
      expect(response.data[0].id, id);
    });
    test('getAllSpaces sends error response', () async {
      when(
          path: 'v1/objects/demo/spaces?limit=10',
          method: 'GET',
          then: FakeResult(_commonObjectError));
      var response = await pubnub.spaces.getAllSpaces(limit: 10);
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });
    test('getAllSpaces throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      expect(pubnub.spaces.getAllSpaces(limit: 10),
          throwsA(TypeMatcher<KeysetException>()));
    });
    test('getSpace should return valid response', () async {
      var spaceId = 'space-1';
      when(
          path: 'v1/objects/demo/spaces/space-1?',
          method: 'GET',
          then: FakeResult(_getSpaceSuccessResponse));
      var response = await pubnub.spaces.getSpace(spaceId);
      expect(response, isA<GetSpaceResult>());
      expect(response.data.id, spaceId);
    });

    test('getSpace throws when spaceId is empty', () async {
      var spaceId = '';
      expect(pubnub.spaces.getSpace(spaceId),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('getSpace throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var spaceId = 'space-1';
      expect(pubnub.spaces.getSpace(spaceId),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('updateSpace throws when spaceId is empty', () async {
      var space = SpaceDetails('my-channel', 'My space',
          description: 'A space that is mine');
      expect(pubnub.spaces.updateSpace(space, ''),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('updateSpace throws when space object is null', () async {
      var space = null;
      expect(pubnub.spaces.updateSpace(space, 'space-1'),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('updateSpace throws if there is no available keyset', () async {
      var space = SpaceDetails('space-1', 'My space',
          description: 'A space that is mine');
      pubnub.keysets.remove('default');
      var spaceId = 'space-1';
      expect(pubnub.spaces.updateSpace(space, spaceId),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('updateSpace returns valid response', () async {
      var space = SpaceDetails('space-1', 'My space',
          description: 'A space that is mine');
      var spaceId = 'space-1';
      when(
          path: 'v1/objects/demo/spaces/space-1',
          method: 'PATCH',
          body: _updateSpaceBody,
          then: FakeResult(_updateSpaceSuccessResponse));
      var response = await pubnub.spaces.updateSpace(space, spaceId);
      expect(response, isA<UpdateSpaceResult>());
      expect(response.status, 200);
      expect(response.data.id, spaceId);
    });

    test('updateSpace error response', () async {
      var space = SpaceDetails('space-1', 'My space',
          description: 'A space that is mine');
      var spaceId = 'space-1';
      when(
          path: 'v1/objects/demo/spaces/space-1',
          method: 'PATCH',
          body: _updateSpaceBody,
          then: FakeResult(_commonObjectError));
      var response = await pubnub.spaces.updateSpace(space, spaceId);
      expect(response, isA<UpdateSpaceResult>());
      expect(response.status, equals(500));
      expect(response.error['message'],
          equals('An unexpected error ocurred while processing the request.'));
    });
    test('deleteSpace throws when spaceId is empty', () async {
      expect(pubnub.spaces.deleteSpace(''),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('updateSpace throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var spaceId = 'space-1';
      expect(pubnub.spaces.deleteSpace(spaceId),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('deleteSpace returns valid response', () async {
      var spaceId = 'space-1';
      var expectedThen = '{"status": "0","data": {}}';
      when(
          path: 'v1/objects/demo/spaces/space-1?',
          method: 'DELETE',
          then: FakeResult(expectedThen));
      var response = await pubnub.spaces.deleteSpace(spaceId);
      expect(response, isA<DeleteSpaceResult>());
      expect(response.status, "0");
      expect(response.data, {});
    });

    test('deleteSpace returns valid response', () async {
      var spaceId = 'space-1';
      var expectedThen = '{"status": "0","data": {}}';
      when(
          path: 'v1/objects/demo/spaces/space-1?',
          method: 'DELETE',
          then: FakeResult(expectedThen));
      var response = await pubnub.spaces.deleteSpace(spaceId);
      expect(response, isA<DeleteSpaceResult>());
      expect(response.status, "0");
      expect(response.data, {});
    });
    test('space() should delegate to spaces.create()', () async {
      var fakePubnub = FakePubNub();
      var keyset = Keyset(subscribeKey: 'test', publishKey: 'test');
      fakePubnub.space('space-1', 'space-name', keyset: keyset);

      var invocation = fakePubnub.invocations[0];

      expect(invocation.isMethod, equals(true));
      expect(invocation.memberName, equals(#space));
      expect(invocation.positionalArguments, equals(['space-1', 'space-name']));
      expect(
          invocation.namedArguments,
          equals({
            #description: null,
            #custom: null,
            #keyset: keyset,
            #using: null
          }));
    });
  });
}
