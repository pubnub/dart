@TestOn('browser')
@Tags(['integration'])

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

  group('browser networking', () {
    late PubNub pubnub;

    setUp(() {
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'demo',
          publishKey: 'demo',
          userId: UserId('dart-web-test'),
        ),
      );
    });

    test('time() makes a successful HTTP request and returns a timetoken', () async {
      var timetoken = await pubnub.time();
      expect(timetoken.value, greaterThan(BigInt.zero));
    });

    test('response contains valid status code and body', () async {
      // time() exercises the full request handler -> response pipeline
      // If the web XMLHttpRequest implementation is broken, this will throw
      var timetoken = await pubnub.time();
      expect(timetoken, isA<Timetoken>());
    });

    test('publish and subscribe work in browser', () async {
      var channel = 'dart-web-test-${DateTime.now().millisecondsSinceEpoch}';

      var subscription = pubnub.subscribe(channels: {channel});

      // Give subscribe a moment to connect
      await Future.delayed(Duration(seconds: 1));

      await pubnub.publish(channel, {'message': 'hello from browser'});

      var envelope = await subscription.messages
          .timeout(Duration(seconds: 10))
          .first;

      expect(envelope.payload, isNotNull);

      await subscription.dispose();
    });
  });
}
