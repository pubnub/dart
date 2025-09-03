import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '../net/fake_net.dart';
part './fixtures/app_context.dart';

void main() {
  late PubNub? pubnub;
  group('DX [app_context]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test', publishKey: 'test', userId: UserId('test')),
          networking: FakeNetworkingModule());
    });

    test('setUUIDMetadata success with valid params', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
        // 'v3/history/sub-key/test/message-counts/test?timetoken=1&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _setUUIDMetadataBody,
      ).then(status: 200, body: _setUUIDMetadataResponse);

      var setUUIDMetadataResponse = await pubnub!.objects.setUUIDMetadata(
        UuidMetadataInput(
          name: 'test',
          custom: {'hello': 'world'},
        ),
        uuid: 'test',
      );
      expect(setUUIDMetadataResponse.metadata.name, equals('test'));
    });

    test('setUUIDMetadata failed with invalid custom fields', () async {
      // Test that UuidMetadataInput constructor throws ArgumentError for invalid custom fields
      expect(
          () => UuidMetadataInput(
                name: 'test',
                custom: {
                  'invalid': [
                    1,
                    2,
                    3
                  ] // Arrays are not allowed in custom fields
                },
              ),
          throwsA(TypeMatcher<ArgumentError>()));
    });

    test('setChannelMetadata success with valid params', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/channels/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
        body: _setChannelMetadataBody,
      ).then(status: 200, body: _setChannelMetadataResponse);
      var channelMetadataInput = ChannelMetadataInput(
          name: 'channel name',
          description: 'channel description',
          custom: {
            'string-key': 'string-value',
          });
      var setChannelMetadataResponse = await pubnub?.objects
          .setChannelMetadata('test', channelMetadataInput);
      expect(setChannelMetadataResponse?.metadata.name, equals('channel name'));
    });

    test('setChannelMetadata failed with invalid custom fields', () async {
      expect(
          () => ChannelMetadataInput(
                  name: 'channel name',
                  description: 'channel description',
                  custom: {
                    'string-key': [1, 2, 3],
                  }),
          throwsA(TypeMatcher<ArgumentError>()));
    });

    test('setChannelMemberMetadata success with valid params', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/channels/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: _setChannelMemberMetadataBody,
      ).then(status: 200, body: _setChannelMemberMetadataResponse);
      var channelMemberMetadataInput =
          ChannelMemberMetadataInput('test', custom: {'role': 'admin'});
      var setChannelMemberMetadataResponse = await pubnub?.objects
          .setChannelMembers('test', [channelMemberMetadataInput]);
      expect(setChannelMemberMetadataResponse?.metadataList?.first.uuid.id,
          equals('test'));
    });

    test('setChannelMemberMetadata failed with invalid custom fields',
        () async {
      expect(
          () => ChannelMemberMetadataInput('test', custom: {
                'role': {'nested-key': 'nested-value'}
              }),
          throwsA(TypeMatcher<ArgumentError>()));
    });

    test('setChannelMembershipMetadata success with valid params', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=channel%2Cstatus%2Ctype&count=true&uuid=test',
        body: _setChannelMembershipMetadataBody,
      ).then(status: 200, body: _setChannelMembershipMetadataResponse);
      var membershipMetadata = [
        MembershipMetadataInput('test', custom: {'starred': 'false'})
      ];

      var membershipMetadataResponse = await pubnub?.objects
          .setMemberships(membershipMetadata, includeChannelFields: true);
      expect(membershipMetadataResponse?.metadataList?.first.channel.id,
          equals('test'));
    });

    test('setChannelMembershipMetadata failed with invalid custom fields',
        () async {
      expect(
          () => MembershipMetadataInput('test', custom: {
                'starred': {'hello': 'world'}
              }),
          throwsA(TypeMatcher<ArgumentError>()));
    });

    // Additional Tests for getUUIDMetadata
    test('getUUIDMetadata success with specific UUID', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test-uuid?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom%2Cstatus%2Ctype&uuid=test',
      ).then(status: 200, body: getUuidMetadataResponse);

      var result = await pubnub!.objects.getUUIDMetadata(
        uuid: 'test-uuid',
        includeCustomFields: true,
        includeStatus: true,
        includeType: true,
      );

      expect(result.metadata!.id, equals('test-uuid'));
      expect(result.metadata!.name, equals('Test User'));
      expect(result.metadata!.email, equals('test@example.com'));
      expect(result.metadata!.custom?['role'], equals('admin'));
    });

    test('getUUIDMetadata success using keyset UUID', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
      ).then(status: 200, body: getUuidMetadataResponse);

      var result = await pubnub!.objects.getUUIDMetadata();

      expect(result.metadata, isNotNull);
    });

    test('getUUIDMetadata with include flags', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom&uuid=test',
      ).then(status: 200, body: getUuidMetadataResponse);

      var result = await pubnub!.objects.getUUIDMetadata(
        includeCustomFields: true,
        includeStatus: false,
        includeType: false,
      );

      expect(result.metadata, isNotNull);
    });

    test('getUUIDMetadata handles non-existent UUID', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/non-existent?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
      ).then(status: 404, body: notFoundErrorResponse);

      expect(
        () async => await pubnub!.objects.getUUIDMetadata(uuid: 'non-existent'),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    // Additional Tests for getChannelMetadata
    test('getChannelMetadata success with valid channelId', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels/test-channel?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom%2Cstatus%2Ctype&uuid=test',
      ).then(status: 200, body: getChannelMetadataResponse);

      var result = await pubnub!.objects.getChannelMetadata(
        'test-channel',
        includeCustomFields: true,
        includeStatus: true,
        includeType: true,
      );

      expect(result.metadata.id, equals('test-channel'));
      expect(result.metadata.name, equals('Test Channel'));
      expect(result.metadata.description, equals('A test channel description'));
      expect(result.metadata.custom?['category'], equals('test'));
    });

    test('getChannelMetadata validates empty channelId', () async {
      expect(
        () async => await pubnub!.objects.getChannelMetadata(''),
        throwsA(TypeMatcher<InvariantException>()),
      );
    });

    test('getChannelMetadata with include flags', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels/test-channel?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom&uuid=test',
      ).then(status: 200, body: getChannelMetadataResponse);

      var result = await pubnub!.objects.getChannelMetadata(
        'test-channel',
        includeCustomFields: true,
        includeStatus: false,
        includeType: false,
      );

      expect(result.metadata, isNotNull);
    });

    // Additional Tests for removeUUIDMetadata
    test('removeUUIDMetadata success with specific UUID', () async {
      when(
        method: 'DELETE',
        path:
            '/v2/objects/test/uuids/test-uuid?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
      ).then(status: 200, body: removeUuidMetadataResponse);

      expect(
        () async => await pubnub!.objects.removeUUIDMetadata(uuid: 'test-uuid'),
        returnsNormally,
      );
    });

    test('removeUUIDMetadata success using keyset UUID', () async {
      when(
        method: 'DELETE',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
      ).then(status: 200, body: removeUuidMetadataResponse);

      expect(
        () async => await pubnub!.objects.removeUUIDMetadata(),
        returnsNormally,
      );
    });

    // Additional Tests for removeChannelMetadata
    test('removeChannelMetadata success', () async {
      when(
        method: 'DELETE',
        path:
            '/v2/objects/test/channels/test-channel?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
      ).then(status: 200, body: removeChannelMetadataResponse);

      expect(
        () async => await pubnub!.objects.removeChannelMetadata('test-channel'),
        returnsNormally,
      );
    });

    test('removeChannelMetadata validates channelId', () async {
      expect(
        () async => await pubnub!.objects.removeChannelMetadata(''),
        throwsA(TypeMatcher<InvariantException>()),
      );
    });

    // Error Handling Tests
    test('setUUIDMetadata handles 401 unauthorized error', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
        body: '{"name":"test"}',
      ).then(status: 401, body: unauthorizedErrorResponse);

      expect(
        () async => await pubnub!.objects.setUUIDMetadata(
          UuidMetadataInput(name: 'test'),
        ),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    test('setChannelMetadata handles 403 forbidden error', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/channels/test-channel?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
        body: '{"name":"test channel"}',
      ).then(status: 403, body: forbiddenErrorResponse);

      expect(
        () async => await pubnub!.objects.setChannelMetadata(
          'test-channel',
          ChannelMetadataInput(name: 'test channel'),
        ),
        throwsA(TypeMatcher<TypeError>()),
      );
    });

    test('setUUIDMetadata handles 412 precondition failed', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
        body: '{"name":"test"}',
      ).then(status: 412, body: preconditionFailedErrorResponse);

      expect(
        () async => await pubnub!.objects.setUUIDMetadata(
          UuidMetadataInput(name: 'test'),
          ifMatchesEtag: 'old-etag',
        ),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    test('Objects APIs handle 500 internal server error', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
      ).then(status: 500, body: internalServerErrorResponse);

      expect(
        () async => await pubnub!.objects.getUUIDMetadata(),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    // Input Validation Tests
    test('UuidMetadataInput validates custom fields with complex objects',
        () async {
      expect(
        () => UuidMetadataInput(
          name: 'test',
          custom: {
            'invalid': {'nested': 'object'} // Objects not allowed
          },
        ),
        throwsA(TypeMatcher<ArgumentError>()),
      );
    });

    test('ChannelMetadataInput validates custom fields with arrays', () async {
      expect(
        () => ChannelMetadataInput(
          name: 'test',
          custom: {
            'invalid': [1, 2, 3] // Arrays not allowed
          },
        ),
        throwsA(TypeMatcher<ArgumentError>()),
      );
    });

    test('ChannelMemberMetadataInput validates complex custom fields',
        () async {
      expect(
        () => ChannelMemberMetadataInput(
          'test-uuid',
          custom: {
            'permissions': {
              'read': true,
              'write': false
            } // nested objects not allowed
          },
        ),
        throwsA(TypeMatcher<ArgumentError>()),
      );
    });

    test('MembershipMetadataInput validates array custom fields', () async {
      expect(
        () => MembershipMetadataInput(
          'test-channel',
          custom: {
            'tags': ['tag1', 'tag2'] // arrays not allowed
          },
        ),
        throwsA(TypeMatcher<ArgumentError>()),
      );
    });

    // Response Parsing Tests
    test('getUUIDMetadata handles response with all fields', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom%2Cstatus%2Ctype&uuid=test',
      ).then(status: 200, body: getUuidMetadataResponse);

      var result = await pubnub!.objects.getUUIDMetadata(
        includeCustomFields: true,
        includeStatus: true,
        includeType: true,
      );

      expect(result.metadata!.id, isNotEmpty);
      expect(result.metadata!.name, isNotNull);
      expect(result.metadata!.email, isNotNull);
      expect(result.metadata!.externalId, isNotNull);
      expect(result.metadata!.profileUrl, isNotNull);
      expect(result.metadata!.custom, isNotNull);
      expect(result.metadata!.updated, isNotNull);
      expect(result.metadata!.eTag, isNotNull);
    });

    test('getChannelMetadata handles response with minimal fields', () async {
      const minimalResponse = '''{
        "status": 200,
        "data": {
          "id": "minimal-channel",
          "updated": "2023-01-01T12:00:00.000Z",
          "eTag": "minimal-etag"
        }
      }''';

      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels/minimal-channel?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
      ).then(status: 200, body: minimalResponse);

      var result = await pubnub!.objects.getChannelMetadata('minimal-channel');

      expect(result.metadata.id, equals('minimal-channel'));
      expect(result.metadata.updated, isNotNull);
      expect(result.metadata.eTag, isNotNull);
      // Optional fields should be null
      expect(result.metadata.name, isNull);
      expect(result.metadata.description, isNull);
      expect(result.metadata.custom, isNull);
    });

    // Boundary Value Tests
    test('setUUIDMetadata handles empty string fields', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
        body: '{"name":"","email":"","externalId":"","profileUrl":""}',
      ).then(status: 200, body: setUuidMetadataResponse);

      expect(
        () async => await pubnub!.objects.setUUIDMetadata(
          UuidMetadataInput(
            name: '',
            email: '',
            externalId: '',
            profileUrl: '',
          ),
        ),
        returnsNormally,
      );
    });

    test('setChannelMetadata handles null description', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/channels/test-channel?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
        body: '{"name":"Test Channel"}',
      ).then(status: 200, body: setChannelMetadataResponse);

      expect(
        () async => await pubnub!.objects.setChannelMetadata(
          'test-channel',
          ChannelMetadataInput(name: 'Test Channel'),
        ),
        returnsNormally,
      );
    });

    // getAllUUIDMetadata Tests
    test('getAllUUIDMetadata success with default parameters', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getAllUuidMetadataResponse);

      var result = await pubnub!.objects.getAllUUIDMetadata();

      expect(result.metadataList, isNotNull);
      expect(result.metadataList!.length, equals(2));
      expect(result.metadataList![0].id, equals('uuid1'));
      expect(result.metadataList![0].name, equals('Test User 1'));
      expect(result.totalCount, equals(2));
      expect(result.next, equals('nextCursor'));
      expect(result.prev, equals('prevCursor'));
    });

    test('getAllUUIDMetadata success with all parameters', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?limit=50&start=cursor1&end=cursor2&filter=name%20LIKE%20%22test*%22&sort=name%3Aasc&include=custom%2Cstatus%2Ctype&count=true&pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
      ).then(status: 200, body: getAllUuidMetadataResponse);

      var result = await pubnub!.objects.getAllUUIDMetadata(
        limit: 50,
        start: 'cursor1',
        end: 'cursor2',
        filter: 'name LIKE "test*"',
        sort: {'name:asc'},
        includeCustomFields: true,
        includeStatus: true,
        includeType: true,
        includeCount: true,
      );

      expect(result.metadataList, isNotNull);
      expect(result.totalCount, isNotNull);
    });

    test('getAllUUIDMetadata handles empty results', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getAllUuidMetadataEmptyResponse);

      var result = await pubnub!.objects.getAllUUIDMetadata();

      expect(result.metadataList, isEmpty);
      expect(result.totalCount, equals(0));
      expect(result.next, isNull);
      expect(result.prev, isNull);
    });

    test('getAllUUIDMetadata with different include combinations', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom&count=true&uuid=test',
      ).then(status: 200, body: getAllUuidMetadataResponse);

      var result = await pubnub!.objects.getAllUUIDMetadata(
        includeCustomFields: true,
        includeStatus: false,
        includeType: false,
      );

      expect(result.metadataList, isNotNull);
    });

    // getAllChannelMetadata Tests
    test('getAllChannelMetadata success with default parameters', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getAllChannelMetadataResponse);

      var result = await pubnub!.objects.getAllChannelMetadata();

      expect(result.metadataList, isNotNull);
      expect(result.metadataList!.length, equals(2));
      expect(result.metadataList![0].id, equals('channel1'));
      expect(result.metadataList![0].name, equals('Test Channel 1'));
      expect(result.totalCount, equals(2));
    });

    test('getAllChannelMetadata success with all parameters', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels?limit=25&start=ch-start&end=ch-end&filter=name%20LIKE%20%22test*%22&sort=updated%3Adesc&include=custom%2Cstatus%2Ctype&count=true&pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
      ).then(status: 200, body: getAllChannelMetadataResponse);

      var result = await pubnub!.objects.getAllChannelMetadata(
        limit: 25,
        start: 'ch-start',
        end: 'ch-end',
        filter: 'name LIKE "test*"',
        sort: {'updated:desc'},
        includeCustomFields: true,
        includeStatus: true,
        includeType: true,
        includeCount: true,
      );

      expect(result.metadataList, isNotNull);
      expect(result.totalCount, isNotNull);
    });

    test('getAllChannelMetadata with filter', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&filter=category%20%3D%3D%20%22public%22&uuid=test',
      ).then(status: 200, body: getAllChannelMetadataResponse);

      var result = await pubnub!.objects.getAllChannelMetadata(
        filter: 'category == "public"',
      );

      expect(result.metadataList, isNotNull);
    });

    test('getAllChannelMetadata with sorting', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&sort=name%3Aasc%2Cupdated%3Adesc&uuid=test',
      ).then(status: 200, body: getAllChannelMetadataResponse);

      var result = await pubnub!.objects.getAllChannelMetadata(
        sort: {'name:asc', 'updated:desc'},
      );

      expect(result.metadataList, isNotNull);
    });

    // getMemberships Tests
    test('getMemberships success with specific UUID', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test-uuid/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getMembershipsResponse);

      var result = await pubnub!.objects.getMemberships(uuid: 'test-uuid');

      expect(result.metadataList, isNotNull);
      expect(result.metadataList!.length, equals(2));
      expect(result.metadataList![0].channel.id, equals('channel1'));
      expect(result.metadataList![0].custom?['role'], equals('member'));
    });

    test('getMemberships success using keyset UUID', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getMembershipsResponse);

      var result = await pubnub!.objects.getMemberships();

      expect(result.metadataList, isNotNull);
    });

    test('getMemberships with all include flags', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom%2Cchannel%2Cchannel.custom%2Cchannel.status%2Cchannel.type%2Cstatus%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getMembershipsResponse);

      var result = await pubnub!.objects.getMemberships(
        includeCustomFields: true,
        includeChannelFields: true,
        includeChannelCustomFields: true,
        includeChannelStatus: true,
        includeChannelType: true,
        includeStatus: true,
        includeType: true,
      );

      expect(result.metadataList, isNotNull);
    });

    test('getMemberships with filter and sort', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&filter=channel.name%20LIKE%20%22test*%22&sort=channel.updated%3Adesc&uuid=test',
      ).then(status: 200, body: getMembershipsResponse);

      var result = await pubnub!.objects.getMemberships(
        filter: 'channel.name LIKE "test*"',
        sort: {'channel.updated:desc'},
      );

      expect(result.metadataList, isNotNull);
    });

    // setMemberships Tests
    test('setMemberships success with membership list', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: setMembershipsBody,
      ).then(status: 200, body: getMembershipsResponse);

      var memberships = [
        MembershipMetadataInput('new-channel',
            custom: {'role': 'member', 'notifications': true})
      ];

      var result = await pubnub!.objects.setMemberships(memberships);

      expect(result.metadataList, isNotNull);
    });

    test('setMemberships with empty metadata list', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: '{"set":[]}',
      ).then(status: 200, body: getMembershipsResponse);

      var result = await pubnub!.objects.setMemberships([]);

      expect(result.metadataList, isNotNull);
    });

    test('setMemberships with include flags', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=custom%2Cchannel%2Cstatus%2Ctype&count=true&uuid=test',
        body: setMembershipsBody,
      ).then(status: 200, body: getMembershipsResponse);

      var memberships = [
        MembershipMetadataInput('new-channel',
            custom: {'role': 'member', 'notifications': true})
      ];

      var result = await pubnub!.objects.setMemberships(
        memberships,
        includeCustomFields: true,
        includeChannelFields: true,
      );

      expect(result.metadataList, isNotNull);
    });

    // manageMemberships Tests
    test('manageMemberships success with set and remove', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: manageMembershipsBody,
      ).then(status: 200, body: getMembershipsResponse);

      var setMemberships = [
        MembershipMetadataInput('add-channel', custom: {'role': 'member'})
      ];
      var removeChannels = {'remove-channel'};

      var result = await pubnub!.objects.manageMemberships(
        setMemberships,
        removeChannels,
      );

      expect(result.metadataList, isNotNull);
    });

    test('manageMemberships with only set operations', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body:
            '{"set":[{"channel":{"id":"add-channel"},"custom":{"role":"member"}}],"delete":[]}',
      ).then(status: 200, body: getMembershipsResponse);

      var setMemberships = [
        MembershipMetadataInput('add-channel', custom: {'role': 'member'})
      ];

      var result = await pubnub!.objects.manageMemberships(
        setMemberships,
        <String>{},
      );

      expect(result.metadataList, isNotNull);
    });

    test('manageMemberships with only remove operations', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: '{"set":[],"delete":[{"channel":{"id":"remove-channel"}}]}',
      ).then(status: 200, body: getMembershipsResponse);

      var removeChannels = {'remove-channel'};

      var result = await pubnub!.objects.manageMemberships(
        <MembershipMetadataInput>[],
        removeChannels,
      );

      expect(result.metadataList, isNotNull);
    });

    // removeMemberships Tests
    test('removeMemberships success with channel IDs', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: removeMembershipsBody,
      ).then(status: 200, body: getMembershipsResponse);

      var channelIds = {'channel-to-remove', 'another-channel-to-remove'};

      var result = await pubnub!.objects.removeMemberships(channelIds);

      expect(result.metadataList, isNotNull);
    });

    // getChannelMembers Tests
    test('getChannelMembers success', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels/test-channel/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getChannelMembersResponse);

      var result = await pubnub!.objects.getChannelMembers('test-channel');

      expect(result.metadataList, isNotNull);
      expect(result.metadataList!.length, equals(2));
      expect(result.metadataList![0].uuid.id, equals('uuid1'));
      expect(result.metadataList![0].custom?['role'], equals('admin'));
    });

    test('getChannelMembers validates channelId', () async {
      expect(
        () async => await pubnub!.objects.getChannelMembers(''),
        throwsA(TypeMatcher<InvariantException>()),
      );
    });

    test('getChannelMembers with UUID include flags', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels/test-channel/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=uuid.custom%2Cuuid.status%2Cuuid.type%2Cstatus%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getChannelMembersResponse);

      var result = await pubnub!.objects.getChannelMembers(
        'test-channel',
        includeUUIDCustomFields: true,
        includeUUIDStatus: true,
        includeUUIDType: true,
        includeUUIDFields: false,
      );

      expect(result.metadataList, isNotNull);
    });

    // setChannelMembers Tests
    test('setChannelMembers success', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/channels/test-channel/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: setChannelMembersBody,
      ).then(status: 200, body: getChannelMembersResponse);

      var members = [
        ChannelMemberMetadataInput('new-member-uuid',
            custom: {'role': 'member', 'invited_by': 'admin-uuid'})
      ];

      var result =
          await pubnub!.objects.setChannelMembers('test-channel', members);

      expect(result.metadataList, isNotNull);
    });

    // manageChannelMembers Tests
    test('manageChannelMembers success with set and remove', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/channels/test-channel/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: manageChannelMembersBody,
      ).then(status: 200, body: getChannelMembersResponse);

      var setMembers = [
        ChannelMemberMetadataInput('add-member-uuid',
            custom: {'role': 'member'})
      ];
      var removeUuids = {'remove-member-uuid'};

      var result = await pubnub!.objects.manageChannelMembers(
        'test-channel',
        setMembers,
        removeUuids,
      );

      expect(result.metadataList, isNotNull);
    });

    // removeChannelMembers Tests
    test('removeChannelMembers success', () async {
      when(
        method: 'PATCH',
        path:
            '/v2/objects/test/channels/test-channel/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
        body: removeChannelMembersBody,
      ).then(status: 200, body: getChannelMembersResponse);

      var uuids = {'member-to-remove'};

      var result =
          await pubnub!.objects.removeChannelMembers('test-channel', uuids);

      expect(result.metadataList, isNotNull);
    });

    // Additional Error Handling Tests
    test('Objects APIs handle HTTP error codes', () async {
      // Test 400 Bad Request
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(
          status: 400,
          body: '{"status":400,"error":{"message":"Bad Request","code":400}}');

      expect(
        () async => await pubnub!.objects.getAllUUIDMetadata(),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    test('Objects APIs handle 429 rate limit error', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&count=true&uuid=test',
      ).then(status: 429, body: rateLimitErrorResponse);

      expect(
        () async => await pubnub!.objects.getAllChannelMetadata(),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    test('Objects APIs handle timeout exceptions', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
      ).then(
          status: 408,
          body:
              '{"status":408,"error":{"message":"Request Timeout","code":408}}');

      expect(
        () async => await pubnub!.objects.getUUIDMetadata(),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    test('Objects APIs handle malformed responses', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels/test-channel?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
      ).then(status: 200, body: 'invalid-json-response');

      expect(
        () async => await pubnub!.objects.getChannelMetadata('test-channel'),
        throwsA(TypeMatcher<Exception>()),
      );
    });

    // Additional Input Validation Tests
    test('Input classes validate required fields', () async {
      expect(
        () => UuidMetadataInput(name: ''), // Empty name should be allowed
        returnsNormally,
      );

      expect(
        () => ChannelMetadataInput(name: ''), // Empty name should be allowed
        returnsNormally,
      );
    });

    test('APIs handle boundary values', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&limit=0&count=true&uuid=test',
      ).then(status: 200, body: getAllUuidMetadataEmptyResponse);

      // Test limit = 0
      var result = await pubnub!.objects.getAllUUIDMetadata(limit: 0);
      expect(result.metadataList, isNotNull);
    });

    test('APIs handle limit boundary values', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&limit=100&count=true&uuid=test',
      ).then(status: 200, body: getAllChannelMetadataResponse);

      // Test limit = 100 (max)
      var result = await pubnub!.objects.getAllChannelMetadata(limit: 100);
      expect(result.metadataList, isNotNull);
    });

    test('APIs handle limit over 100', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&limit=150&count=true&uuid=test',
      ).then(status: 200, body: getAllUuidMetadataResponse);

      // Test limit > 100 (should be handled by server)
      var result = await pubnub!.objects.getAllUUIDMetadata(limit: 150);
      expect(result.metadataList, isNotNull);
    });

    // Additional Response Parsing Tests
    test('Response classes parse complete data', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test?include=custom%2Cstatus%2Ctype&pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
      ).then(status: 200, body: getUuidMetadataResponse);

      var result = await pubnub!.objects.getUUIDMetadata(
        includeCustomFields: true,
        includeStatus: true,
        includeType: true,
      );

      // Verify all fields are correctly deserialized
      expect(result.metadata!.id, isNotEmpty);
      expect(result.metadata!.name, isNotNull);
      expect(result.metadata!.email, isNotNull);
      expect(result.metadata!.externalId, isNotNull);
      expect(result.metadata!.profileUrl, isNotNull);
      expect(result.metadata!.custom, isNotNull);
      expect(result.metadata!.updated, isNotNull);
      expect(result.metadata!.eTag, isNotNull);
    });

    test('Response classes handle null fields', () async {
      const responseWithNulls = '''{
        "status": 200,
        "data": {
          "id": "test-uuid",
          "name": null,
          "email": null,
          "externalId": null,
          "profileUrl": null,
          "custom": null,
          "updated": "2023-01-01T12:00:00.000Z",
          "eTag": "test-etag"
        }
      }''';

      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&uuid=test',
      ).then(status: 200, body: responseWithNulls);

      var result = await pubnub!.objects.getUUIDMetadata();

      expect(result.metadata!.id, equals('test-uuid'));
      expect(result.metadata!.name, isNull);
      expect(result.metadata!.email, isNull);
      expect(result.metadata!.externalId, isNull);
      expect(result.metadata!.profileUrl, isNull);
      expect(result.metadata!.custom, isNull);
      expect(result.metadata!.updated, isNotNull);
      expect(result.metadata!.eTag, isNotNull);
    });

    test('Large response handling', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=status%2Ctype&limit=100&count=true&uuid=test',
      ).then(status: 200, body: getAllUuidMetadataResponse);

      // Test with large limit to ensure efficient processing
      var result = await pubnub!.objects.getAllUUIDMetadata(limit: 100);
      expect(result.metadataList, isNotNull);
      // Verify efficient memory usage
      expect(result.metadataList!.length, lessThanOrEqualTo(100));
    });

    test('Membership response with channel details', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/uuids/test/channels?pnsdk=PubNub-Dart%2F${PubNub.version}&include=channel.custom%2Cchannel.status%2Cchannel.type%2Cstatus%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getMembershipsResponse);

      var result = await pubnub!.objects.getMemberships(
        includeChannelCustomFields: true,
        includeChannelStatus: true,
        includeChannelType: true,
      );

      expect(result.metadataList, isNotNull);
      expect(result.metadataList![0].channel.id, isNotEmpty);
      expect(result.metadataList![0].channel.name, isNotNull);
    });

    test('Channel members response with UUID details', () async {
      when(
        method: 'GET',
        path:
            '/v2/objects/test/channels/test-channel/uuids?pnsdk=PubNub-Dart%2F${PubNub.version}&include=uuid.custom%2Cuuid.status%2Cuuid.type%2Cstatus%2Ctype&count=true&uuid=test',
      ).then(status: 200, body: getChannelMembersResponse);

      var result = await pubnub!.objects.getChannelMembers(
        'test-channel',
        includeUUIDCustomFields: true,
        includeUUIDStatus: true,
        includeUUIDType: true,
      );

      expect(result.metadataList, isNotNull);
      expect(result.metadataList![0].uuid.id, isNotEmpty);
      expect(result.metadataList![0].custom, isNotNull);
    });
  });
}
