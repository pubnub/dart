import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import '../../net/fake_net.dart';

part 'fixtures/channel_metadata.dart';

void main() {
  PubNub pubnub;
  group('DX [objectMetadata] [channel]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            Keyset(
                subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('uuid-1')),
            name: 'default',
            useAsDefault: true);
    });

    test('#getAllChannelMetadata()', () async {
      when(
        path:
            'v2/objects/demo/channels?limit=10&count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getAllMetadataSuccessResponse);
      var response = await pubnub.objects.getAllChannelMetadata(limit: 10);
      expect(response, isA<GetAllChannelMetadataResult>());
      expect(response.metadataList[0].id, 'my-channel');
    });

    test('#getChannelMetadata()', () async {
      when(
        path:
            'v2/objects/demo/channels/my-channel?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getMetadataSuccessResponse);
      var response = await pubnub.objects.getChannelMetadata('my-channel');
      expect(response, isA<GetChannelMetadataResult>());
      expect(response.metadata.id, 'my-channel');
    });

    test('#setChannelMetadata()', () async {
      var channelMetadataInput = ChannelMetadataInput(
          name: 'My channel', description: 'A channel that is mine');
      when(
        path:
            'v2/objects/demo/channels/my-channel?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _setChannelMetadataBody,
      ).then(status: 200, body: _setChannelMetadataSuccessResponse);
      var response = await pubnub.objects
          .setChannelMetadata('my-channel', channelMetadataInput);
      expect(response, isA<SetChannelMetadataResult>());
      expect(response.metadata.id, 'my-channel');
    });
    test('#removeChannelMetadata()', () async {
      when(
        path:
            'v2/objects/demo/channels/my-channel?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'DELETE',
      ).then(status: 200, body: _removeMetadataSuccessResponse);
      var response = await pubnub.objects.removeChannelMetadata('my-channel');
      expect(response, isA<RemoveChannelMetadataResult>());
    });
  });
}
