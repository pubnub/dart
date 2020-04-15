import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/core/keyset.dart';

import '../net/fake_net.dart';

void main() {
  PubNub pubnub;
  group('DX [subscribe]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'demo', publishKey: 'demo'),
            name: 'default', useAsDefault: true);
    });

    // TODO: write subscribe tests
  });
}
