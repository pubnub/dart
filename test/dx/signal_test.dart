import 'package:pubnub/src/core/keyset.dart';
import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '../net/fake_net.dart';

part './fixtures/signal.dart';

void main() {
  PubNub pubnub;
  group('DX [signal]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'demo', publishKey: 'demo'),
            name: 'default', useAsDefault: true);
    });

    test('signal successfully returns SignalResult', () async {
      when(
          path: 'signal/demo/demo/0/test/0/%7B%22typing%22:true%7D?',
          method: 'GET',
          then: FakeResult(_signalSuccessResponse));

      var response = await pubnub.signal('test', {"typing": true});

      expect(response.isError, equals(false));
    });
  });
}
