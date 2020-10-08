import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import '../net/fake_net.dart';

void main() {
  PubNub pubnub;
  group('DX [time]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            Keyset(subscribeKey: 'demo', publishKey: 'demo', uuid: null),
            name: 'default',
            useAsDefault: true);
    });

    test('time successfully returns TimeResult', () async {
      when(path: 'time/0?pnsdk=PubNub-Dart%2F${PubNub.version}', method: 'GET')
          .then(status: 200, body: '[123]');

      var response = await pubnub.time();

      expect(response, isA<Timetoken>());
      expect(response.value, isA<int>());
    });
  });
}
