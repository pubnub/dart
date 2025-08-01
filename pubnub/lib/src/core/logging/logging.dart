import 'dart:async';
import 'dart:mirrors';

import 'package:pubnub/pubnub.dart';
import '../../networking/response/response.dart';
import '../net/request_type.dart';
import '../core.dart';

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

Map<String, dynamic> extractObjectProperties(Object obj,
    {List<String> skipProperties = const ['keyset']}) {
  final result = <String, dynamic>{};

  try {
    final mirror = reflect(obj);
    final declarations = mirror.type.declarations;

    for (var declaration in declarations.values) {
      if (declaration is VariableMirror && !declaration.isStatic) {
        final name = MirrorSystem.getName(declaration.simpleName);

        if (skipProperties.contains(name)) {
          continue;
        }

        try {
          final value = mirror.getField(declaration.simpleName).reflectee;
          result[name] = value;
        } catch (e) {
          result[name] = '<inaccessible>';
        }
      }
    }
  } catch (e) {
    // Fallback: try to convert to string representation
    result['toString'] = obj.toString();
  }

  return result;
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
        messageString +=
            '\n\t  Networking: ${pubnub.networking.runtimeType.toString().split('.').last}';
        messageString +=
            '\n\t  Parser: ${pubnub.parser.runtimeType.toString().split('.').last}';
        messageString +=
            '\n\t  Crypto: ${pubnub.crypto.runtimeType.toString().split('.').last}';

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
            messageString += '\n\t    Subscribe Key: ${keyset.subscribeKey}';
            messageString +=
                '\n\t    Publish Key: ${keyset.publishKey ?? 'not provided'}';
            messageString +=
                '\n\t    Secret Key: ${keyset.secretKey != null ? 'provided' : 'not provided'}';
            messageString += '\n\t    User ID: ${keyset.userId}';
            messageString +=
                '\n\t    Auth Key: ${keyset.authKey != null ? 'provided' : 'not provided'}';
            messageString +=
                '\n\t    Cipher Key: ${keyset.cipherKey != null ? 'provided' : 'not provided'}';
            if (keyset.settings.isNotEmpty) {
              messageString += '\n\t    Settings: ${keyset.settings}';
            }
            if (i == 0 && keysetNames[i] == 'default') {
              messageString += '\n\t    (Default)';
            }
          }
        }
      } else if (detailsType == LogEventDetailsType.apiParametersInfo) {
        // Handle both Map and Object types
        Map<String, dynamic> detailsMap;
        if (details is Map) {
          detailsMap = details as Map<String, dynamic>;
        } else if (details != null) {
          // Extract properties from any object
          detailsMap = extractObjectProperties(details!);
        } else {
          detailsMap = {};
        }
        messageString +=
            '\n\t${detailsMap.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n\t')}';
      } else if (detailsType == LogEventDetailsType.networkRequestInfo) {
        var requestMap = details as Map<String, dynamic>;

        for (var entry in requestMap.entries) {
          switch (entry.key) {
            case 'type':
              var requestType = entry.value as RequestType;
              messageString += '\n\tMethod: ${requestType.method}';
              break;
            case 'uri':
              messageString += '\n\tURL: ${entry.value}';
              break;
            case 'headers':
              var headers = entry.value as Map<String, dynamic>;
              if (headers.isNotEmpty) {
                messageString += '\n\tHeaders:';
                for (var headerEntry in headers.entries) {
                  messageString +=
                      '\n\t  ${headerEntry.key}: ${headerEntry.value}';
                }
              }
              break;
            case 'body':
              if (entry.value != null) {
                if (entry.value is List<int>) {
                  var length = entry.value.length;
                  messageString +=
                      '\n\tBody:binary content with length $length';
                } else {
                  messageString += '\n\tBody: ${entry.value}';
                }
              }
              break;
          }
        }
      } else if (detailsType == LogEventDetailsType.networkResponseInfo) {
        var responseMap = details as Map<String, dynamic>;
        messageString += '\n\tURL: ${responseMap['request'].uri}';
        messageString +=
            '\n\tStatus Code: ${responseMap['response'].statusCode}';
        var response = responseMap['response'] as Response;
        if (response.headers.containsKey('server')) {
          messageString +=
              '\n\tBody: binary content length ${response.byteList.length}';
        } else {
          messageString += '\n\tBody: ${response.text}';
        }
      }
    } catch (e) {
      messageString += '\n logging error: $e';
    }
    return messageString;
  }
}
