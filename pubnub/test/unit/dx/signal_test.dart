import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import '../net/fake_net.dart';
part './fixtures/signal.dart';

void main() {
  late PubNub pubnub;
  group('DX [signal]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            'default',
            Keyset(
                subscribeKey: 'demo',
                uuid: UUID('test-uuid'),
                publishKey: 'demo'),
            useAsDefault: true);
    });

    test('signal successfully returns SignalResult', () async {
      when(
        path:
            'signal/demo/demo/0/test/0/%7B%22typing%22:true%7D?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _signalSuccessResponse);

      var response = await pubnub.signal('test', {'typing': true});

      expect(response.isError, equals(false));
    });
  });
}
