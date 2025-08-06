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

        // Create PubNub instance with logging enabled at info level
        // Using demo keys to avoid authentication errors
        var pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo',
              publishKey: 'demo',
              uuid: UUID('test-uuid')),
          logging: LoggingConfiguration(
            logLevel: Level.info, // Enable logging at info level
            loggerName: 'test-pubnub',
            logToConsole: false, // Disable console output for testing
          ),
        );

        // Get the instance logger and listen to it
        var logger = pubnub.logger;
        expect(logger, isNotNull);

        // Listen to log messages
        var subscription = logger!.stream.listen((record) {
          capturedLogs.add(record);
        });

        // Perform an operation that generates info logs
        // The signal API should log 'Signal API call' at info level
        try {
          await pubnub.signal('test-channel', {'message': 'test'});
        } catch (e) {
          // Signal might still fail for other reasons, but won't cause auth errors
        }

        // Wait for all async operations to complete
        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        // Verify that info level logs were captured
        var infoLogs =
            capturedLogs.where((log) => log.level == Level.info).toList();
        expect(infoLogs, isNotEmpty,
            reason: 'Should have captured info level logs');

        // Check for the specific 'Signal API call' log
        var signalLog = infoLogs
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
            logLevel: Level.warning, // Enable logging at warning level only
            logToConsole: false,
          ),
        );

        // Get the instance logger and listen to it
        var logger = pubnub.logger;
        var subscription = logger!.stream.listen((record) {
          capturedLogs.add(record);
        });

        // Perform an operation that generates info logs
        try {
          await pubnub.signal('test-channel', {'message': 'test'});
        } catch (e) {
          // Signal might still fail for other reasons, but won't cause auth errors
        }

        // Wait for all async operations to complete
        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        // Verify that info level logs were NOT captured (since we set level to warning)
        var infoLogs =
            capturedLogs.where((log) => log.level == Level.info).toList();
        expect(infoLogs, isEmpty,
            reason:
                'Should NOT capture info logs when level is set to warning');

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
            logLevel: Level.warning, // Start with warning level
            logToConsole: false,
          ),
        );

        // Get the instance logger and listen to it
        var logger = pubnub.logger;
        var subscription = logger!.stream.listen((record) {
          capturedLogs.add(record);
        });

        // First operation - should not log info messages
        try {
          await pubnub.signal('test-channel', {'message': 'test1'});
        } catch (e) {}

        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        var infoLogsBeforeChange =
            capturedLogs.where((log) => log.level == Level.info).length;
        expect(infoLogsBeforeChange, equals(0),
            reason: 'Should not log info messages at warning level');

        // Change log level to info
        pubnub.setLogLevel(Level.info);
        capturedLogs.clear();

        // Second operation - should now log info messages
        try {
          await pubnub.signal('test-channel', {'message': 'test2'});
        } catch (e) {}

        await pumpEventQueue();
        await Future.delayed(Duration(milliseconds: 100));

        var infoLogsAfterChange =
            capturedLogs.where((log) => log.level == Level.info).length;
        expect(infoLogsAfterChange, greaterThan(0),
            reason: 'Should log info messages after changing level');

        // Clean up
        await subscription.cancel();
        await pumpEventQueue();
        await pubnub.dispose();
      });
    });
  });
}
