import 'package:test/test.dart';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/pam/pam.dart';

import '../net/fake_net.dart';

part './fixtures/pam.dart';

void main() {
  PubNub pubnub;
  group('DX [PAM]', () {
    final currentVersion = PubNub.version;

    setUp(() {
      PubNub.version = '1.0.0';
      Core.version = '1.0.0';
      Time.mock(DateTime.fromMillisecondsSinceEpoch(1234567890000));

      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            Keyset(subscribeKey: 'test', publishKey: 'test', secretKey: 'test'),
            name: 'default',
            useAsDefault: true);
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
    test('grant should return valid result', () async {
      when(request: _grantRequest).then(response: _grantSuccessResponse);

      var response = await pubnub.grant(
        {'authKey'},
        channels: {'my_channel'},
        read: true,
        write: false,
        manage: false,
        ttl: 1440,
      );
      expect(response.message, equals('Success'));
    });

    test('requestToken.send throws when resources are empty', () async {
      var request = pubnub.requestToken(ttl: 1440, meta: {
        'user-id': 'jay@example.com',
        'contains-unicode': 'The 來 test.'
      });
      expect(request.send(), throwsA(TypeMatcher<InvariantException>()));
    });
    test('requestToken.send should return valid result', () async {
      when(request: _grantTokenRequest)
          .then(response: _grantTokenSuccessResponse);

      var request = pubnub.requestToken(ttl: 1440, meta: {
        'user-id': 'jay@example.com',
        'contains-unicode': 'The 來 test.'
      })
        ..add(ResourceType.channel, 'inbox-jay', read: true, write: true);

      var response = await request.send();

      expect(response, isA<Token>());
    });

    test('requestToken.send returns error response', () async {
      when(request: _grantTokenRequest)
          .then(response: _grantTokenFailureResponse);
      var request = pubnub.requestToken(ttl: 1440, meta: {
        'user-id': 'jay@example.com',
        'contains-unicode': 'The 來 test.'
      })
        ..add(ResourceType.channel, 'inbox-jay', read: true, write: true);

      expect(request.send(), throwsA(TypeMatcher<PubNubException>()));
    });
  });
}
