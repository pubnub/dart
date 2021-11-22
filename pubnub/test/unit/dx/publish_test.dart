import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import '../net/fake_net.dart';
part './fixtures/publish.dart';

void main() {
  PubNub? pubnub;
  group('DX [publish]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('test')),
          networking: FakeNetworkingModule());
    });

    test('publish throws if channel name is an empty string', () async {
      expect(
          pubnub?.publish('', 42), throwsA(TypeMatcher<InvariantException>()));
    });

    test('publish throws if there is no available keyset', () async {
      pubnub?.keysets.remove('default');
      expect(
          pubnub?.publish('test', 42), throwsA(TypeMatcher<KeysetException>()));
    });
  });
}
