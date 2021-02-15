import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import '../../net/fake_net.dart';
part 'fixtures/uuid_metadata.dart';

void main() {
  PubNub pubnub;
  group('DX [objects] [uuid]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            Keyset(
                subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('uuid-1')),
            name: 'default',
            useAsDefault: true);
    });
    test('#getAllUUIDMetadata()', () async {
      when(
        path:
            'v2/objects/demo/uuids?limit=10&count=true&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getAllMetadataSuccessResponse);
      var response = await pubnub.objects.getAllUUIDMetadata(limit: 10);
      expect(response, isA<GetAllUuidMetadataResult>());
      expect(response.metadataList[0].id, 'uuid-1');
    });
    test('#getUUIDMetadata()', () async {
      when(
        path:
            'v2/objects/demo/uuids/uuid-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getMetadataSuccessResponse);
      var response = await pubnub.objects.getUUIDMetadata();
      expect(response, isA<GetUuidMetadataResult>());
      expect(response.metadata.id, 'uuid-1');
    });
    test('#getUUIDMetadata() with explicitly provided uuid', () async {
      when(
        path:
            'v2/objects/demo/uuids/uuid-2?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _getMetadataSuccessResponse);
      var response = await pubnub.objects.getUUIDMetadata(uuid: 'uuid-2');
      expect(response, isA<GetUuidMetadataResult>());
      expect(response.metadata.id, 'uuid-1');
    });
    test('#setUUIDMetadata()', () async {
      var uuidMetadataInput =
          UuidMetadataInput(name: 'John Doe', email: 'jack@twitter.com');
      when(
        path:
            'v2/objects/demo/uuids/uuid-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _setUuidMetadataBody,
      ).then(status: 200, body: _setUuidMetadataSuccessResponse);
      var response = await pubnub.objects.setUUIDMetadata(uuidMetadataInput);
      expect(response, isA<SetUuidMetadataResult>());
      expect(response.metadata.id, 'uuid-1');
    });
    test('#setUUIDMetadata() with explicitly provided uuid', () async {
      var uuidMetadataInput =
          UuidMetadataInput(name: 'John Doe', email: 'jack@twitter.com');
      when(
        path:
            'v2/objects/demo/uuids/uuid-2?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'PATCH',
        body: _setUuidMetadataBody,
      ).then(status: 200, body: _setUuidMetadataSuccessResponse);
      var response = await pubnub.objects
          .setUUIDMetadata(uuidMetadataInput, uuid: 'uuid-2');
      expect(response, isA<SetUuidMetadataResult>());
      expect(response.metadata.id, 'uuid-1');
    });
    test('#removeUUIDMetadata()', () async {
      when(
        path:
            'v2/objects/demo/uuids/uuid-1?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'DELETE',
      ).then(status: 200, body: _removeMetadataSuccessResponse);
      var response = await pubnub.objects.removeUUIDMetadata();
      expect(response, isA<RemoveUuidMetadataResult>());
    });
  });
}
