import 'package:test/test.dart';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import '../net/fake_net.dart';

void main() {
  late PubNub pubnub;
  group('DX [PAM]', () {
    final currentVersion = PubNub.version;

    setUp(() {
      PubNub.version = '1.0.0';
      Core.version = '1.0.0';
      Time.mock(DateTime.fromMillisecondsSinceEpoch(1234567890000));

      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test',
              publishKey: 'test',
              secretKey: 'test',
              authKey: 'test',
              uuid: UUID('test')),
          networking: FakeNetworkingModule());
    });

    tearDown(() {
      PubNub.version = currentVersion;
      Core.version = currentVersion;
      Time.unmock();
    });

    test('grant throws for when keyset is not provided', () {
      pubnub.keysets.remove('default');
      expect(pubnub.grant(<String>{'auth'}),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('grant throws for when channels and uuids provided', () async {
      expect(
          pubnub.grant(<String>{'auth'}, channels: {'ch1'}, uuids: {'uuid1'}),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('grant throws for when channelGroups and uuids provided', () async {
      expect(
          pubnub.grant(<String>{'auth'},
              channelGroups: {'cg1'}, uuids: {'uuid1'}),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('requestToken.send throws when resources are empty', () async {
      var request = pubnub.requestToken(ttl: 1440, meta: {
        'user-id': 'jay@example.com',
        'contains-unicode': 'The 來 test.'
      });
      expect(request.send(), throwsA(TypeMatcher<InvariantException>()));
    });
  });
}
