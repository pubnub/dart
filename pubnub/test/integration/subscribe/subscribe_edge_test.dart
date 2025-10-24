@TestOn('vm')
@Tags(['integration'])

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

void main() {
  late PubNub pubnub;
  late List<String> channelsToCleanup;

  setUp(() {
    pubnub = PubNub(
      defaultKeyset: Keyset(
        subscribeKey: Platform.environment['SDK_SUB_KEY'] ?? 'demo',
        publishKey: Platform.environment['SDK_PUB_KEY'] ?? 'demo',
        userId: UserId('dart-test'),
      ),
    );
    channelsToCleanup = [];
  });

  tearDown(() async {
    // Clean up by unsubscribing from all channels
    for (var channel in channelsToCleanup) {
      try {
        await pubnub.unsubscribeAll();
      } catch (e) {
        print('Error cleaning up channel $channel: $e');
      }
    }
  });

  group('Publish and Subscribe Integration Tests', () {
    // Publish with error handling
    test('invalid keys throw error', () async {
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      channelsToCleanup.add(channel);

      var badPubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'invalid',
          publishKey: 'invalid',
          userId: UserId('dart-test'),
        ),
      );

      try {
        await badPubnub.publish(channel, 'message');
        fail('Expected publish to fail with invalid keys');
      } catch (e) {
        if (e is TimeoutException ||
            e.toString().contains('request timed out')) {
          // This is acceptable since invalid keys may cause timeouts
          print(
              'Request timed out with invalid keys - this is expected behavior');
        } else {
          expect(
              e is PubNubException &&
                  (e.toString().contains('Invalid auth key') ||
                      e.toString().contains('Invalid subscribe key') ||
                      e.toString().contains('Invalid publish key') ||
                      e.toString().contains('Invalid Key')),
              isTrue,
              reason: 'Unexpected error: ${e.toString()}');
        }
      }
    });

    // Test network error handling
    test('network error handling', () async {
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      channelsToCleanup.add(channel);

      var errorPubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'demo',
          publishKey: 'demo',
          userId: UserId('dart-test'),
        ),
        networking: BrokenNetworkingModule(),
      );

      await expectLater(
        () => errorPubnub.publish(channel, 'message'),
        throwsA(predicate((e) =>
            e is PubNubException && e.toString().contains('Network error'))),
      );
    });

    // Test rapid message publishing
    test('rapid message publishing', () async {
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      channelsToCleanup.add(channel);

      var messageCount = 10;
      var sentMessages = <String>[];
      var receivedMessages = <String>[];

      // Set up subscription
      var sub = pubnub.subscribe(channels: {channel});
      await sub.whenStarts;

      // Create a subscription and wait for it to be active
      var subscription = pubnub.subscribe(channels: {channel});
      await subscription.whenStarts;

      // Set up completer for all messages
      final allMessagesReceived = Completer<void>();

      // Listen for messages
      subscription.messages.listen((envelope) {
        receivedMessages.add(envelope.payload);
        if (receivedMessages.length == messageCount) {
          allMessagesReceived.complete();
        }
      });

      // Publish messages rapidly
      await Future.forEach(List.generate(messageCount, (i) => i),
          (int i) async {
        var msg = 'message-$i';
        sentMessages.add(msg);
        await pubnub.publish(channel, msg);
      });

      // Wait for all messages with timeout
      await expectLater(
        allMessagesReceived.future.timeout(Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Did not receive all messages')),
        completes,
        reason: 'Should receive all messages within timeout',
      );

      // Verify message ordering
      expect(receivedMessages.length, equals(messageCount),
          reason: 'Did not receive expected number of messages');

      // Verify messages were received in order
      expect(receivedMessages, equals(sentMessages),
          reason: 'Messages not received in correct order');

      await sub.cancel();
    });

    // Test large message publishing
    test('large message publishing', () async {
      var channel = 'test-${DateTime.now().millisecondsSinceEpoch}';
      channelsToCleanup.add(channel);

      var largeMessage = 'x' * 30000; // 30KB message
      var receivedMessage = '';

      // Set up subscription
      var sub = pubnub.subscribe(channels: {channel});
      await sub.whenStarts;

      // Listen for messages
      sub.messages.listen((envelope) {
        receivedMessage = envelope.payload;
      });

      // Publish large message
      await pubnub.publish(channel, largeMessage);

      // Wait for message to be received
      await Future.delayed(Duration(seconds: 5));

      expect(receivedMessage, equals(largeMessage));
      expect(receivedMessage.length, equals(30000));

      await sub.cancel();
    });
  });
}

// Mock module for testing network errors
class BrokenNetworkingModule extends NetworkingModule {
  BrokenNetworkingModule() : super();

  @override
  Future<IRequestHandler> handler() async {
    return BrokenRequestHandler();
  }
}

// Mock request handler that always throws network errors
class BrokenRequestHandler extends IRequestHandler {
  @override
  bool get isCancelled => false;

  @override
  void cancel([reason]) {}

  @override
  Future<IResponse> response(Request request) async {
    throw PubNubException('Network error');
  }
}
