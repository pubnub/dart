import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import '../net/fake_net.dart';

void main() {
  group('DX [time]', () {
    late PubNub pubnub;

    test('time successfully returns TimeResult', () async {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('test')),
          networking: FakeNetworkingModule());

      when(
        path: 'time/0?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[123]');

      var response = await pubnub.time();

      expect(response, isA<Timetoken>());
      expect(response.value, isA<BigInt>());
    });

    test('time successfully returns TimeResult without any keyset', () async {
      pubnub = PubNub(networking: FakeNetworkingModule());

      when(
        path: 'time/0?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[123]');

      var response = await pubnub.time();

      expect(response, isA<Timetoken>());
      expect(response.value, isA<BigInt>());
    });
  });
}
