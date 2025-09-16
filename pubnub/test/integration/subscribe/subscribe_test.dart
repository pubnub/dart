@TestOn('vm')
@Tags(['integration'])

import 'dart:io';
import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_utils.dart';

void main() {
  final SUBSCRIBE_KEY = Platform.environment['SDK_SUB_KEY'] ?? 'demo';
  final PUBLISH_KEY = Platform.environment['SDK_PUB_KEY'] ?? 'demo';

  late Subscriber subscriber;
  late PubNub pubnub;

  group('Subscribe_loop', () {
    test('without message encryption', () async {
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: SUBSCRIBE_KEY,
          publishKey: PUBLISH_KEY,
          uuid: UUID('dart-test'),
        ),
      );
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      var message = 'hello';
      subscriber = Subscriber.init(pubnub, SUBSCRIBE_KEY);

      subscriber.subscribe(channel);

      await Future.delayed(Duration(seconds: 2));

      await pubnub.publish(channel, message);

      await subscriber.expectMessage(channel, message);
    });

    test('with message encryption enabled', () async {
      var cipherKey = CipherKey.fromUtf8('enigma');
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      var message = 'hello pubnub!';
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: SUBSCRIBE_KEY,
          publishKey: PUBLISH_KEY,
          cipherKey: cipherKey,
          uuid: UUID('dart-test'),
        ),
      );

      subscriber = Subscriber.init(pubnub, SUBSCRIBE_KEY, cipherKey: cipherKey);

      subscriber.subscribe(channel);

      await Future.delayed(Duration(seconds: 2));

      await pubnub.publish(channel, message);

      await subscriber.expectMessage(channel, message);
    });

    test('with custom timetoken', () async {
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: SUBSCRIBE_KEY,
          publishKey: PUBLISH_KEY,
          uuid: UUID('dart-test'),
        ),
      );
      var customOldTimetoken =
          Timetoken(BigInt.from(DateTime.now().microsecondsSinceEpoch * 10));
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      var message = 'hello';

      await pubnub.publish(channel, message);

      subscriber = Subscriber.init(pubnub, SUBSCRIBE_KEY);

      var subscription =
          subscriber.createSubscription(channel, timetoken: customOldTimetoken);

      subscription!.subscribe();

      await Future.delayed(Duration(seconds: 2));

      await subscriber.expectMessage(channel, message);
    });

    test('with crypto configuration and plain message', () async {
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      var message = 'hello pubnub!';
      pubnub = PubNub(
        defaultKeyset: Keyset(
            subscribeKey: SUBSCRIBE_KEY,
            publishKey: PUBLISH_KEY,
            userId: UserId('dart-test')),
      );
      var pubnubWithCrypto = PubNub(
        crypto:
            CryptoModule.aesCbcCryptoModule(CipherKey.fromUtf8('cipherKey')),
        defaultKeyset: Keyset(
          subscribeKey: SUBSCRIBE_KEY,
          publishKey: PUBLISH_KEY,
          userId: UserId('dart-test'),
        ),
      );
      subscriber = Subscriber.init(pubnubWithCrypto, SUBSCRIBE_KEY);
      subscriber.subscribe(channel);
      await Future.delayed(Duration(seconds: 2));
      await pubnub.publish(channel, message);

      await subscriber.expectMessage(
          channel,
          message,
          PubNubException(
              'Can not decrypt the message payload. Please check keyset or crypto configuration.'));
    });

    tearDown(() async {
      await subscriber.cleanup();
      await pubnub.unsubscribeAll();
    });
  });
}
