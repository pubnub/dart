import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/networking.dart';
import 'package:pubnub/logging.dart';

void main() {
  group('Retry Policy', () {
    test('non-subscribe requests should NEVER retry regardless of retry policy',
        () async {
      // Test with exponential retry policy
      var pubnubWithRetry = PubNub(
        networking: NetworkingModule(
          origin: 'invalid.domain.that.does.not.exist.com',
          retryPolicy: RetryPolicy.exponential(maxRetries: 5),
        ),
        defaultKeyset: Keyset(
            subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('test-uuid')),
      );

      // Test with None retry policy
      var pubnubNoneRetry = PubNub(
        networking: NetworkingModule(
          origin: 'invalid.domain.that.does.not.exist.com',
          retryPolicy: RetryPolicy.none(),
        ),
        defaultKeyset: Keyset(
            subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('test-uuid')),
      );

      // Test 1: Publish with exponential retry policy (should still fail immediately)
      print(
          'Testing publish WITH exponential retry policy (should fail immediately)...');
      var startTime = DateTime.now();
      try {
        await pubnubWithRetry.publish('test-channel', {'message': 'test'});
        fail('Publish should have failed');
      } catch (e) {
        var duration = DateTime.now().difference(startTime);
        print('Publish failed after ${duration.inMilliseconds}ms');
        expect(duration.inSeconds, lessThan(3),
            reason: 'Non-subscribe requests should fail immediately');
      }

      // Test 2: Signal with None retry policy (should fail immediately)
      print(
          '\nTesting signal with None retry policy (should fail immediately)...');
      startTime = DateTime.now();
      try {
        await pubnubNoneRetry.signal('test-channel', {'message': 'test'});
        fail('Signal should have failed');
      } catch (e) {
        var duration = DateTime.now().difference(startTime);
        print('Signal failed after ${duration.inMilliseconds}ms');
        expect(duration.inSeconds, lessThan(3),
            reason: 'Non-subscribe requests should fail immediately');
      }

      // Test 3: Batch with linear retry policy (should fail immediately)
      var pubnubLinearRetry = PubNub(
        networking: NetworkingModule(
          origin: 'invalid.domain.that.does.not.exist.com',
          retryPolicy: RetryPolicy.linear(maxRetries: 10),
        ),
        defaultKeyset: Keyset(
            subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('test-uuid')),
      );

      print('\nTesting batch.fetchMessages with linear retry policy...');
      startTime = DateTime.now();
      try {
        await pubnubLinearRetry.batch.fetchMessages({'test-channel'});
        fail('Batch should have failed');
      } catch (e) {
        var duration = DateTime.now().difference(startTime);
        print('Batch failed after ${duration.inMilliseconds}ms');
        expect(duration.inSeconds, lessThan(3),
            reason: 'Non-subscribe requests should fail immediately');
      }
    });

    test('subscribe requests should follow retry policy when configured',
        () async {
      var retryAttempts = 0;

      // Create a logger to count retry attempts
      var logger = StreamLogger.root('test', logLevel: Level.all);
      logger.stream.listen((record) {
        if (record.message.toString().contains('retry #')) {
          retryAttempts++;
        }
      });

      await provideLogger(logger, () async {
        // Test with linear retry policy
        var pubnub = PubNub(
          networking: NetworkingModule(
            origin: 'invalid.domain.that.does.not.exist.com',
            retryPolicy: RetryPolicy.linear(
                maxRetries: 3, backoff: 100, maximumDelay: 500),
          ),
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
        );

        // Subscribe will retry according to policy
        var subscription = pubnub.subscribe(channels: {'test-channel'});

        // Wait a bit to allow some retry attempts
        await Future.delayed(Duration(seconds: 2));

        // Cancel the subscription
        await subscription.cancel();

        // Should have seen retry attempts for subscribe
        print('Subscribe retry attempts observed: $retryAttempts');
        expect(retryAttempts, greaterThan(0),
            reason: 'Subscribe should retry with configured policy');
      });
    });

    test(
        'subscribe requests with None retry policy should fail without retries',
        () async {
      var logMessages = <String>[];

      // Create a logger to capture messages
      var logger = StreamLogger.root('test', logLevel: Level.all);
      logger.stream.listen((record) {
        logMessages.add(record.message.toString());
      });

      await provideLogger(logger, () async {
        // Test with None retry policy
        var pubnub = PubNub(
          networking: NetworkingModule(
            origin: 'invalid.domain.that.does.not.exist.com',
            retryPolicy: RetryPolicy.none(), // Explicit none policy
          ),
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
        );

        // Subscribe should fail without retries when using None retry policy
        var subscription = pubnub.subscribe(channels: {'test-channel'});

        // Wait a bit
        await Future.delayed(Duration(seconds: 2));

        // Cancel the subscription
        await subscription.cancel();

        // Check that we did NOT get retry messages
        var retryLogs = logMessages
            .where((msg) =>
                    msg.contains('retry #2') // Would indicate a retry attempt
                )
            .toList();

        print('Retry logs found: ${retryLogs.length}');
        expect(retryLogs.length, equals(0),
            reason: 'Subscribe with None retry policy should not retry');
      });
    });

    test('verify all retry policy types', () {
      // Test exponential retry policy
      var exponential = RetryPolicy.exponential(maxRetries: 5);
      expect(exponential.maxRetries, equals(5)); // Should use provided value
      expect(exponential.toString(), equals('exponential (max: 150000)'));
      expect(exponential, isA<ExponentialRetryPolicy>());

      // Test linear retry policy
      var linear = RetryPolicy.linear(maxRetries: 3, backoff: 100);
      expect(linear.maxRetries, equals(3));
      expect(linear.toString(), equals('linear (backoff: 100, max: 60000)'));
      expect(linear, isA<LinearRetryPolicy>());

      // Test none retry policy
      var none = RetryPolicy.none();
      expect(none.maxRetries, equals(0));
      expect(none.toString(), equals('none'));
      // expect(none, isA<NoneRetryPolicy>());

      // Test that NetworkingModule handles all types
      var networkingExp = NetworkingModule(retryPolicy: exponential);
      expect(networkingExp.toString(), contains('retryPolicy: exponential'));

      var networkingNone = NetworkingModule(retryPolicy: none);
      expect(networkingNone.toString(), contains('retryPolicy: none'));

      var networkingNull = NetworkingModule(retryPolicy: null);
      expect(networkingNull.toString(),
          contains('retryPolicy: exponential')); // null defaults to exponential
    });

    test('default PubNub constructor uses exponential retry for subscribe only',
        () async {
      // When no networking configuration is provided, PubNub should default to
      // exponential retry policy, but still only apply it to subscribe requests
      var logger = StreamLogger.root('test', logLevel: Level.all);
      var retryLogs = <String>[];

      logger.stream.listen((record) {
        if (record.message.toString().contains('retry #')) {
          retryLogs.add(record.message.toString());
        }
      });

      await provideLogger(logger, () async {
        // Create PubNub with default configuration (no networking module specified)
        var pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
        );

        // Verify the default networking module has exponential retry policy
        expect(
            pubnub.networking.toString(), contains('retryPolicy: exponential'));

        // But non-subscribe requests should still fail immediately
        // We can't test with invalid domain easily in default config, but we can
        // verify the configuration is correct
        print('Default PubNub instance created with: ${pubnub.networking}');
      });
    });

    test('None retry policy prevents ALL retries including subscribe',
        () async {
      var logger = StreamLogger.root('test', logLevel: Level.all);
      var logs = <String>[];

      logger.stream.listen((record) {
        logs.add(record.message.toString());
      });

      await provideLogger(logger, () async {
        // Create PubNub with explicit None retry policy
        var pubnub = PubNub(
          networking: NetworkingModule(
            origin: 'invalid.domain.that.does.not.exist.com',
            retryPolicy: RetryPolicy.none(),
          ),
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
        );

        // Test that even subscribe requests don't retry with None policy
        var subscription = pubnub.subscribe(channels: {'test-channel'});

        await Future.delayed(Duration(seconds: 3));
        await subscription.cancel();

        // Should not see any retry attempts beyond the first try
        var retryBeyondFirst = logs
            .where(
                (log) => log.contains('retry #2') || log.contains('retry #3'))
            .toList();

        expect(retryBeyondFirst.isEmpty, isTrue,
            reason:
                'None retry policy should prevent all retries, even for subscribe');

        // Test non-subscribe requests also fail immediately
        var startTime = DateTime.now();
        try {
          await pubnub.publish('test', {'msg': 'test'});
        } catch (e) {
          var duration = DateTime.now().difference(startTime);
          expect(duration.inSeconds, lessThan(2),
              reason: 'Non-subscribe with None policy should fail immediately');
        }
      });
    });

    test('only subscribe requests are affected by retry policy', () async {
      // This test verifies that retry policy ONLY affects subscribe requests
      var logger = StreamLogger.root('test', logLevel: Level.all);
      var logs = <String>[];

      logger.stream.listen((record) {
        logs.add(record.message.toString());
      });

      await provideLogger(logger, () async {
        // Create PubNub with aggressive retry policy
        var pubnub = PubNub(
          networking: NetworkingModule(
            origin: 'invalid.domain.that.does.not.exist.com',
            retryPolicy: RetryPolicy.linear(
                maxRetries: 5, backoff: 100, maximumDelay: 500),
          ),
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
        );

        // Test various non-subscribe operations
        var operations = [
          () => pubnub.publish('test', {'msg': 'test'}),
          () => pubnub.signal('test', {'sig': 'test'}),
          () => pubnub.batch.fetchMessages({'test'}),
          () => pubnub.time(),
        ];

        for (var op in operations) {
          try {
            await op();
          } catch (e) {
            // Expected to fail
          }
        }

        // Look for actual retry attempts (retry #2 or higher indicates a retry happened)
        var actualRetries = logs
            .where((log) =>
                log.contains('retry #2') ||
                log.contains('retry #3') ||
                log.contains('retry #4') ||
                log.contains('retry #5'))
            .toList();

        if (actualRetries.isNotEmpty) {
          print('Unexpected retry attempts found:');
          for (var log in actualRetries) {
            print('  - $log');
          }
        }

        // First attempt logs (retry #1) are expected, but no actual retries should occur
        expect(actualRetries.isEmpty, isTrue,
            reason:
                'Non-subscribe operations should not actually retry (no retry #2+ logs)');
      });
    });
  });
}
