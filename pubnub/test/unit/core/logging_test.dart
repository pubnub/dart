import 'package:test/test.dart';

import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';

// A utility function to ensure all pending microtasks are processed
Future<void> pumpEventQueue() => Future.delayed(Duration.zero);

class FakeLogger extends ILogger {
  List<String> messages = [];

  @override
  void log(int level, message) {
    messages.add(message);
  }

  @override
  ILogger get(String scope) => this;
}

void main() {
  group('Logging', () {
    group('[injectLogger]', () {
      test('should return the logger from Zone.current', () async {
        var logger = FakeLogger();

        await provideLogger(logger, () async {
          var logger = injectLogger('test.logger');

          logger.info('test');
        });

        expect(logger.messages, equals(['test']));
      });

      test('should return the DummyLogger if run without provideLogger', () {
        var lazyLogger = injectLogger('some.scope');

        expect(lazyLogger.logger, isA<DummyLogger>());

        expect(() {
          lazyLogger.info('ignored message');
        }, returnsNormally);
      });
    });

    group('[PubNub constructor logging]', () {
      test('should enable logging when LoggingConfiguration is provided',
          () async {
        // Create a list to capture log messages
        List<LogRecord> capturedLogs = [];

        // Create PubNub instance with logging enabled at all level
        // Using demo keys to avoid authentication errors
        var pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
          logging: LoggingConfiguration(
            logLevel: Level.all, // Enable all logging levels
            loggerName: 'test-pubnub',
            logToConsole: false, // Disable console output for testing
          ),
        );

        // Get the instance logger and listen to it
        var logger = pubnub.logger as StreamLogger;
        expect(logger, isNotNull);

        // Listen to log messages
        var subscription = logger.stream.listen((record) {
          capturedLogs.add(record);
        });

        // Perform an operation that generates logs
        // The signal API logs at silly and fine levels
        try {
          await pubnub.signal('test-channel', {'message': 'test'});
        } catch (e) {
          // Signal might still fail for other reasons, but won't cause auth errors
        }

        // Wait for all async operations to complete
        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        // Verify that logs were captured (signal API logs at silly and fine levels)
        var allLogs = capturedLogs
            .where((log) => log.level == Level.silly || log.level == Level.fine)
            .toList();
        expect(allLogs, isNotEmpty,
            reason: 'Should have captured logs from signal API');

        // Check for the specific 'Signal API call' log (logged at silly level)
        var signalLog = capturedLogs
            .where((log) => log.message.toString().contains('Signal API call'))
            .toList();
        expect(signalLog, isNotEmpty,
            reason: 'Should have logged "Signal API call"');

        // Verify logger name is set correctly
        expect(logger.name, equals('test-pubnub'));

        // Clean up
        await subscription.cancel();
        await pumpEventQueue();
        await pubnub.dispose();
      });

      test('should respect different log levels', () async {
        // Create a list to capture log messages
        List<LogRecord> capturedLogs = [];

        // Create PubNub instance with logging enabled at warning level
        // Using demo keys to avoid authentication errors
        var pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
          logging: LoggingConfiguration(
            logLevel:
                Level.warning, // Enable logging at warning level only (80)
            logToConsole: false,
          ),
        );

        // Get the instance logger and listen to it
        var logger = pubnub.logger as StreamLogger;
        var subscription = logger.stream.listen((record) {
          capturedLogs.add(record);
        });

        // Perform an operation that generates silly and fine logs
        try {
          await pubnub.signal('test-channel', {'message': 'test'});
        } catch (e) {
          // Signal might still fail for other reasons, but won't cause auth errors
        }

        // Wait for all async operations to complete
        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        // Verify that silly/fine level logs were NOT captured (since we set level to warning)
        // Signal API logs at silly (640) and fine (500) levels, both > warning (80)
        var sillyLogs =
            capturedLogs.where((log) => log.level == Level.silly).toList();
        var fineLogs =
            capturedLogs.where((log) => log.level == Level.fine).toList();
        expect(sillyLogs, isEmpty,
            reason:
                'Should NOT capture silly logs when level is set to warning');
        expect(fineLogs, isEmpty,
            reason:
                'Should NOT capture fine logs when level is set to warning');

        // Clean up
        await subscription.cancel();
        await pumpEventQueue();
        await pubnub.dispose();
      });

      test('should dynamically change log level', () async {
        // Create a list to capture log messages
        List<LogRecord> capturedLogs = [];

        // Create PubNub instance with logging enabled at warning level
        // Using demo keys to avoid authentication errors
        var pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
          logging: LoggingConfiguration(
            logLevel: Level.warning, // Start with warning level (80)
            logToConsole: false,
          ),
        );

        // Get the instance logger and listen to it
        var logger = pubnub.logger as StreamLogger;
        var subscription = logger.stream.listen((record) {
          capturedLogs.add(record);
        });

        // First operation - should not log silly/fine messages
        try {
          await pubnub.signal('test-channel', {'message': 'test1'});
        } catch (e) {}

        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        var sillyLogsBeforeChange =
            capturedLogs.where((log) => log.level == Level.silly).length;
        expect(sillyLogsBeforeChange, equals(0),
            reason: 'Should not log silly messages at warning level');

        // Change log level to all (to capture silly and fine logs)
        pubnub.setLogLevel(Level.all);
        capturedLogs.clear();

        // Second operation - should now log silly/fine messages
        try {
          await pubnub.signal('test-channel', {'message': 'test2'});
        } catch (e) {}

        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        // Signal API logs at silly and fine levels
        var logsAfterChange = capturedLogs
            .where((log) => log.level == Level.silly || log.level == Level.fine)
            .length;
        expect(logsAfterChange, greaterThan(0),
            reason:
                'Should log silly/fine messages after changing level to all');

        // Clean up
        await subscription.cancel();
        await pumpEventQueue();
        await pubnub.dispose();
      });
    });
  });
}
