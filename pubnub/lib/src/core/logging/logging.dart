import 'dart:async';

import 'package:pubnub/pubnub.dart';
import '../../networking/response/response.dart';
import '../core.dart';
import '../net/net.dart';

final _pubnubLoggerModuleKey = #pubnub.logging;

/// Provides a [logger] to the code inside [body].
Future<R> provideLogger<R>(ILogger logger, Future<R> Function() body) async {
  var result = await runZoned<Future<R>>(body,
      zoneValues: {_pubnubLoggerModuleKey: logger});

  return result;
}

/// @nodoc
class DummyLogger extends ILogger {
  @override
  DummyLogger get(String scope) => this;

  @override
  void log(int level, message) {}
}

/// @nodoc
class LazyLogger implements ILogger {
  final String _id;
  final ILogger Function() _obtainLogger;

  LazyLogger(this._id, this._obtainLogger);

  ILogger get logger => _obtainLogger().get(_id);

  @override
  void fatal(message) => logger.fatal(message);

  @override
  ILogger get(String id) => logger.get(id);

  @override
  void info(message) => logger.info(message);

  @override
  void log(int level, message) => logger.log(level, message);

  @override
  void severe(message) => logger.severe(message);

  @override
  void shout(message) => logger.shout(message);

  @override
  void fine(message) => logger.fine(message);

  @override
  void silly(message) => logger.silly(message);

  @override
  void verbose(message) => logger.verbose(message);

  @override
  void warning(message) => logger.warning(message);
}

/// A logger that forwards logs to multiple underlying loggers.
class CompositeLogger extends ILogger {
  final List<ILogger> targets;

  CompositeLogger(this.targets);

  @override
  ILogger get(String id) {
    return CompositeLogger(targets.map((t) => t.get(id)).toList());
  }

  @override
  void log(int level, dynamic message) {
    for (final target in targets) {
      target.log(level, message);
    }
  }

  @override
  void shout(dynamic message) {
    for (final target in targets) {
      target.shout(message);
    }
  }

  @override
  void fatal(dynamic message) {
    for (final target in targets) {
      target.fatal(message);
    }
  }

  @override
  void severe(dynamic message) {
    for (final target in targets) {
      target.severe(message);
    }
  }

  @override
  void warning(dynamic message) {
    for (final target in targets) {
      target.warning(message);
    }
  }

  @override
  void info(dynamic message) {
    for (final target in targets) {
      target.info(message);
    }
  }

  @override
  void fine(dynamic message) {
    for (final target in targets) {
      target.fine(message);
    }
  }

  @override
  void verbose(dynamic message) {
    for (final target in targets) {
      target.verbose(message);
    }
  }

  @override
  void silly(dynamic message) {
    for (final target in targets) {
      target.silly(message);
    }
  }
}

/// Get a logger from the provider.
///
/// [id] is an arbitrary parameter, and different Logger implementations will handle it differently.
///
/// If there is no provider, returned logger will be a [DummyLogger].
LazyLogger injectLogger(String id) {
  return LazyLogger(id, () {
    // First check the current Zone for a logger (existing behavior)
    var zoneLogger = Zone.current[_pubnubLoggerModuleKey];
    if (zoneLogger != null) {
      return zoneLogger;
    }

    // If no Zone logger, check for global PubNub logger (NEW)
    var globalLogger = _getGlobalPubNubLogger();
    if (globalLogger != null) {
      return globalLogger;
    }

    // Fallback to dummy logger
    return DummyLogger();
  });
}

/// Get the global PubNub logger if available
ILogger? _getGlobalPubNubLogger() {
  try {
    for (var entry in globalLoggerRegistry.entries) {
      if (entry.key.startsWith('pubnub-')) {
        return entry.value;
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// Global registry for loggers that can be accessed across the SDK
final Map<String, ILogger> globalLoggerRegistry = {};

abstract class ILogger {
  ILogger get(String id);
  void log(int level, dynamic message);

  void shout(dynamic message) => log(Level.shout, message);
  void fatal(dynamic message) => log(Level.fatal, message);
  void severe(dynamic message) => log(Level.severe, message);
  void warning(dynamic message) => log(Level.warning, message);
  void info(dynamic message) => log(Level.info, message);
  void fine(dynamic message) => log(Level.fine, message);
  void verbose(dynamic message) => log(Level.verbose, message);
  void silly(dynamic message) => log(Level.silly, message);
}

/// Represents the level of a log record.
///
/// Those are not strict.
/// How (and if) they work depends on the implementation of the logger.
abstract class Level {
  /// Intended to disable logging at all.
  static final int off = 0;

  /// Intended for an extra debug information. Only use when debugging.
  static final int shout = 10;

  /// Intended for fatal errors that end in application crash or exit.
  static final int fatal = 20;

  /// Intended for severe exceptions that need to be resolved.
  static final int severe = 40;

  /// Intended for warnings.
  static final int warning = 80;

  /// Intended for informational messages.
  static final int info = 160;

  /// Intended for the fine mode.
  static final int fine = 500;

  /// Intended for the verbose mode.
  static final int verbose = 320;

  /// Intended for the super verbose mode.
  static final int silly = 640;

  /// Intended to enable all logging.
  static final int all = 10000;

  static final Map<int, String> levels = const {
    0: 'off',
    10: 'shout',
    20: 'fatal',
    40: 'severe',
    80: 'warning',
    160: 'info',
    320: 'verbose',
    500: 'fine',
    640: 'silly',
    10000: 'all'
  };

  static String getName(int level) {
    return levels.entries
        .map((entry) => MapEntry((entry.key - level).abs(), entry.value))
        .reduce((current, next) => current.key > next.key ? next : current)
        .value;
  }
}

Map<String, dynamic> _parametersToJson(Object? obj) {
  if (obj == null) return {};
  if (obj is Map<String, dynamic>) return obj;

  try {
    final dynamic dynamicObject = obj;
    final dynamic maybeMap = dynamicObject.toJson();
    if (maybeMap is Map<String, dynamic>) {
      return maybeMap;
    }
  } catch (_) {
    // ignore and fallback
  }

  // string value as fallback
  return {'value': obj.toString()};
}

/// Enum for different types of log event details
enum LogEventDetailsType {
  pubNubInstanceInfo,
  apiParametersInfo,
  networkRequestInfo,
  networkResponseInfo,
}

/// Enhanced LogEvent that can handle both Map and Object details
class LogEvent {
  final String? message;
  final Object? details;
  final LogEventDetailsType? detailsType;

  LogEvent({this.message, this.details, this.detailsType});

  @override
  String toString() {
    var messageString = message ?? '';
    try {
      if (detailsType == LogEventDetailsType.pubNubInstanceInfo) {
        var pubnub = details as PubNub;
        var keysets = pubnub.keysets;

        messageString += '\n\tPubNub Instance Information:';
        messageString += '\n\tInstance ID: ${Core.instanceId}';
        messageString += '\n\tVersion: ${Core.version}';

        // Log module information
        messageString += '\n\tModules:';
        messageString += '\n\t  Networking: ${pubnub.networking}';
        messageString += '\n\t  Parser: ${pubnub.parser}';
        messageString += '\n\t  Crypto: ${pubnub.crypto}';

        // Log keyset information
        messageString += '\n\tKeysets:';
        var allKeysets = keysets.keysets;
        if (allKeysets.isEmpty) {
          messageString += '\n\t  No keysets configured';
        } else {
          // Get all keyset names by trying to access them
          var keysetNames = <String>[];
          try {
            // Try to get the default keyset name by checking which one is the default
            var defaultKeyset = keysets.defaultKeyset;
            for (var keyset in allKeysets) {
              // Find the name by comparing with default
              if (keyset == defaultKeyset) {
                keysetNames.add('default');
              } else {
                // For non-default keysets, we'll use a generic name
                keysetNames.add('keyset_${keysetNames.length + 1}');
              }
            }
          } catch (e) {
            // If no default keyset, just number them
            for (var i = 0; i < allKeysets.length; i++) {
              keysetNames.add('keyset_${i + 1}');
            }
          }

          for (var i = 0; i < allKeysets.length; i++) {
            var keyset = allKeysets[i];
            var name = keysetNames[i];
            messageString += '\n\t  $name:';
            messageString += keyset.toString();
            if (i == 0 && keysetNames[i] == 'default') {
              messageString += '\n\t    (Default)';
            }
          }
        }
      } else if (detailsType == LogEventDetailsType.apiParametersInfo) {
        final detailsMap = _parametersToJson(details);
        messageString +=
            '\n\t${detailsMap.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n\t')}';
      } else if (detailsType == LogEventDetailsType.networkRequestInfo) {
        messageString += (details as Request).toString();
      } else if (detailsType == LogEventDetailsType.networkResponseInfo) {
        if (details is Response) {
          messageString += details.toString();
        } else if (details is Map) {
          var detailsMap = details as Map<String, dynamic>;
          var request = detailsMap['request'] as Request;
          var response = detailsMap['response'] as Response;
          messageString += '\n\tURL: ${request.uri}';
          messageString += response.toString();
        }
      }
    } catch (e) {
      messageString += '\n logging error: $e';
    }
    return messageString;
  }
}
