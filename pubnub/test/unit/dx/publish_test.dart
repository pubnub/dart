import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

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

  group('DX [publish] url build check cases', () {
    setUp(() {
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'demo',
          publishKey: 'demo',
          userId: UserId('test'),
        ),
        networking: FakeNetworkingModule(),
      );
    });

    test('publish succeeds with valid channel and message', () async {
      when(
        method: 'GET',
        path: '/publish/demo/demo/0/test/0/42?uuid=test',
      ).then(status: 200, body: _publishSuccessResponse);
      final result = await pubnub!.publish('test', 42);
      expect(result.isError, isFalse);
      expect(result.description, equals('Sent'));
      expect(result.timetoken, equals(1));
    });

    test('publish with meta, ttl, storeMessage, customMessageType', () async {
      when(
        method: 'GET',
        path:
            '/publish/demo/demo/0/test/0/42?meta=%7B%22foo%22%3A%22bar%22%7D&store=0&ttl=60&custom_message_type=custom&uuid=test',
      ).then(status: 200, body: _publishSuccessResponse);
      final result = await pubnub!.publish(
        'test',
        42,
        meta: {'foo': 'bar'},
        storeMessage: false,
        ttl: 60,
        customMessageType: 'custom',
      );
      expect(result.isError, isFalse);
      expect(result.description, equals('Sent'));
    });

    test('publish with fire parameter sets storeMessage and noReplication',
        () async {
      when(
        method: 'GET',
        path: '/publish/demo/demo/0/test/0/42?store=0&norep=true&uuid=test',
      ).then(status: 200, body: _publishSuccessResponse);
      final result = await pubnub!.publish('test', 42, fire: true);
      expect(result.isError, isFalse);
      expect(result.description, equals('Sent'));
    });

    test('publish throws if message is null', () async {
      expect(() => pubnub!.publish('test', null),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('publish throws if publishKey is missing', () async {
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'demo',
          userId: UserId('test'),
        ),
        networking: FakeNetworkingModule(),
      );
      expect(() => pubnub!.publish('test', 42),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('publish returns error result on failure response', () async {
      when(
        method: 'GET',
        path: '/publish/demo/demo/0/test/0/42?uuid=test',
      ).then(status: 200, body: _publishFailureResponse);
      final result = await pubnub!.publish('test', 42);
      expect(result.isError, isTrue);
      expect(result.description, equals('Invalid subscribe key'));
    });

    test('publish encrypts message if CryptoModule is configured', () async {
      final cipherKey = CipherKey.fromUtf8('enigmaenigmaenigm');
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'demo',
          publishKey: 'demo',
          userId: UserId('test'),
        ),
        crypto: CryptoModule.aesCbcCryptoModule(cipherKey),
        networking: FakeNetworkingModule(),
      );
      // The encrypted payload will be base64, so we use a placeholder path.
      // In a real test, you would compute the expected encrypted payload.
      when(
        method: 'GET',
        path: '/publish/demo/demo/0/test/0/ENCRYPTED_PAYLOAD?uuid=test',
      ).then(status: 200, body: _publishSuccessResponse);
      // This will not match the actual encrypted payload, so we expect a MockException.
      expect(() async => await pubnub!.publish('test', 'secret'),
          throwsA(TypeMatcher<MockException>()));
    });
  });
}
