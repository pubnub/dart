import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pubnub/logging.dart';

/// Configuration for PubNub instance logging.
///
/// This class encapsulates all logging-related configuration options,
class LoggingConfiguration {
  final int logLevel;
  final String? loggerName;
  final bool logToConsole;
  final String? logFormat;
  final ILogger? customLogger;

  const LoggingConfiguration({
    this.logLevel = 0, // Level.off
    this.loggerName,
    this.logToConsole = true,
    this.logFormat,
    this.customLogger,
  });

  /// Creates a logger based on this configuration
  ILogger createLogger(String instanceId) {
    if (customLogger != null) {
      return customLogger!;
    }

    return StreamLogger.root(
      loggerName ?? 'PubNub-$instanceId',
      logLevel: logLevel,
    );
  }

  /// Sets up console output for the logger if enabled
  StreamSubscription<LogRecord>? setupConsoleOutput(StreamLogger logger) {
    if (!logToConsole) return null;

    final format = logFormat ?? r'$time ${level.name} $scope: $message';
    return logger.stream.listen(
      LogRecord.createPrinter(format),
    );
  }
}

/// A mixin that provides instance-level logging functionality
mixin PubNubLogging {
  StreamLogger? _instanceLogger;
  StreamSubscription<LogRecord>? _logSubscription;
  String? _loggingInstanceId;

  /// The logger for this PubNub instance
  StreamLogger? get logger => _instanceLogger;

  /// Initialize logging for this instance
  @protected
  void initializeLogging(LoggingConfiguration? config, String instanceId) {
    if (config == null || config.logLevel == 0) {
      // Level.off
      return;
    }

    _loggingInstanceId = instanceId;
    _instanceLogger = config.createLogger(instanceId) as StreamLogger?;
    _logSubscription = config.setupConsoleOutput(_instanceLogger!);

    // Register in global registry for advanced use cases
    globalLoggerRegistry['pubnub-$instanceId'] = _instanceLogger!;
  }

  /// Change the log level dynamically for this instance
  void setLogLevel(int level) {
    _instanceLogger?.logLevel = level;
  }

  /// Clean up logging resources for this instance
  @protected
  Future<void> cleanupLogging() async {
    await _logSubscription?.cancel();
    _logSubscription = null;

    if (_instanceLogger != null && _loggingInstanceId != null) {
      globalLoggerRegistry.remove('pubnub-$_loggingInstanceId');
      await _instanceLogger!.dispose();
      _instanceLogger = null;
    }
  }
}
