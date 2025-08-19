@TestOn('browser')

import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';

void main() {
  test('package can be imported and instantiated in browser', () {
    final pubnub = PubNub(
      defaultKeyset: Keyset(
        subscribeKey: 'sub-key',
        publishKey: 'pub-key',
        userId: UserId('dart-user'),
      ),
    );
    expect(pubnub, isNotNull);
    expect(PubNub.version, isNotEmpty);
  });
}
