import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import '../../net/fake_net.dart';

part 'fixtures/membership_metadata.dart';

void main() {
  PubNub pubnub;
  group('DX [objects] [membership]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            Keyset(
                subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('uuid-1')),
            name: 'default',
            useAsDefault: true);
    });

    test('#getMemberships()', () async {
      when(
        path:
            'v2/objects/demo/uuids/uuid-2/channels?limit=10&count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _membershipsMetadataSuccessResponse);
      var response =
          await pubnub.objects.getMemberships(uuid: 'uuid-2', limit: 10);
      expect(response, isA<MembershipsResult>());
      expect(response.metadataList[0].channel.id, 'my-channel');
    });

    test('#manageMemberships()', () async {
      when(
              path:
                  'v2/objects/demo/uuids/uuid-1/channels?count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'PATCH',
              body: _manageMemershipMetadataBody)
          .then(status: 200, body: _membershipsMetadataSuccessResponse);
      var setDataInput = [
        MembershipMetadataInput('my-channel', custom: {'starred': false})
      ];
      var response =
          await pubnub.objects.manageMemberships(setDataInput, {'channel-1'});
      expect(response, isA<MembershipsResult>());
      expect(response.metadataList[0].channel.id, 'my-channel');
    });

    test('#setMemberships()', () async {
      when(
              path:
                  'v2/objects/demo/uuids/uuid-1/channels?count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'PATCH',
              body: _setMemershipsMetadataBody)
          .then(status: 200, body: _membershipsMetadataSuccessResponse);
      var setDataInput = [
        MembershipMetadataInput('my-channel', custom: {'starred': false})
      ];
      var response = await pubnub.objects.setMemberships(setDataInput);
      expect(response, isA<MembershipsResult>());
      expect(response.metadataList[0].channel.id, 'my-channel');
    });
    test('#removeMemberships()', () async {
      when(
              path:
                  'v2/objects/demo/uuids/uuid-1/channels?count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'PATCH',
              body: _removeMemershipsMetadataBody)
          .then(status: 200, body: _membershipsMetadataSuccessResponse);
      var response = await pubnub.objects.removeMemberships({'channel-1'});
      expect(response, isA<MembershipsResult>());
      expect(response.metadataList[0].channel.id, 'my-channel');
    });

    test('#getChannelMembers()', () async {
      when(
        path:
            'v2/objects/demo/channels/my-channel/uuids?limit=10&count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _membersMetadataSuccessResponse);
      var response =
          await pubnub.objects.getChannelMembers('my-channel', limit: 10);
      expect(response, isA<ChannelMembersResult>());
      expect(response.metadataList[0].uuid.id, 'uuid-1');
    });

    test('#manageChannelMembers()', () async {
      when(
              path:
                  'v2/objects/demo/channels/my-channel/uuids?count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'PATCH',
              body: _manageMemersMetadataBody)
          .then(status: 200, body: _membersMetadataSuccessResponse);
      var setDataInput = [
        ChannelMemberMetadataInput('uuid-1', custom: {'role': 'admin'})
      ];
      var response = await pubnub.objects
          .manageChannelMembers('my-channel', setDataInput, {'uuid-1'});
      expect(response, isA<ChannelMembersResult>());
      expect(response.metadataList[0].uuid.id, 'uuid-1');
    });

    test('#setMembersMetadata()', () async {
      when(
        path:
            'v2/objects/demo/channels/my-channel/uuids?count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _setMembersMetadataBody,
      ).then(status: 200, body: _membersMetadataSuccessResponse);
      var setDataInput = [
        ChannelMemberMetadataInput('uuid-1', custom: {'role': 'admin'})
      ];
      var response =
          await pubnub.objects.setChannelMembers('my-channel', setDataInput);
      expect(response, isA<ChannelMembersResult>());
      expect(response.metadataList[0].uuid.id, 'uuid-1');
    });
    test('#removeChannelMembers()', () async {
      when(
              path:
                  'v2/objects/demo/channels/my-channel/uuids?count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'PATCH',
              body: _removeMembersMetadataBody)
          .then(status: 200, body: _membersMetadataSuccessResponse);
      var response =
          await pubnub.objects.removeChannelMembers('my-channel', {'uuid-2'});
      expect(response, isA<ChannelMembersResult>());
      expect(response.metadataList[0].uuid.id, 'uuid-1');
    });
  });
}
