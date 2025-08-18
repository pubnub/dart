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
    final streamLogger = StreamLogger.root(
      loggerName ?? 'PubNub-$instanceId',
      logLevel: logLevel,
    );

    if (customLogger != null) {
      // Fan out to both StreamLogger (default) and the provided custom logger
      return CompositeLogger([streamLogger, customLogger!]);
    }

    return streamLogger;
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
  ILogger? _instanceLogger;
  StreamSubscription<LogRecord>? _logSubscription;
  String? _loggingInstanceId;

  /// The logger for this PubNub instance
  ILogger? get logger => _instanceLogger;

  /// Initialize logging for this instance
  @protected
  void initializeLogging(LoggingConfiguration? config, String instanceId) {
    if (config == null) {
      return;
    }

    _loggingInstanceId = instanceId;
    final createdLogger = config.createLogger(instanceId);
    _instanceLogger = createdLogger;

    // Setup console output if StreamLogger is part of the logger chain
    if (config.logLevel != 0) {
      if (createdLogger is StreamLogger) {
        _logSubscription = config.setupConsoleOutput(createdLogger);
      } else if (createdLogger is CompositeLogger) {
        for (final target in createdLogger.targets) {
          if (target is StreamLogger) {
            _logSubscription = config.setupConsoleOutput(target);
            break;
          }
        }
      }
    }

    // Register in global registry for advanced use cases
    globalLoggerRegistry['pubnub-$instanceId'] = _instanceLogger!;
  }

  /// Change the log level dynamically for this instance
  void setLogLevel(int level) {
    final current = _instanceLogger;
    if (current is StreamLogger) {
      current.logLevel = level;
    } else if (current is CompositeLogger) {
      for (final target in current.targets) {
        if (target is StreamLogger) {
          target.logLevel = level;
        }
      }
    }
  }

  /// Clean up logging resources for this instance
  @protected
  Future<void> cleanupLogging() async {
    await _logSubscription?.cancel();
    _logSubscription = null;

    if (_instanceLogger != null && _loggingInstanceId != null) {
      globalLoggerRegistry.remove('pubnub-$_loggingInstanceId');
      final current = _instanceLogger;
      if (current is StreamLogger) {
        await current.dispose();
      } else if (current is CompositeLogger) {
        for (final target in current.targets) {
          if (target is StreamLogger) {
            await target.dispose();
          }
        }
      }
      _instanceLogger = null;
    }
  }
}
