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
  });
}
