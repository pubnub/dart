import 'dart:async';

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
  return LazyLogger(
      id, () => Zone.current[_pubnubLoggerModuleKey] ?? DummyLogger());
}

abstract class ILogger {
  ILogger get(String id);
  void log(int level, dynamic message);

  void shout(dynamic message) => log(Level.shout, message);
  void fatal(dynamic message) => log(Level.fatal, message);
  void severe(dynamic message) => log(Level.severe, message);
  void warning(dynamic message) => log(Level.warning, message);
  void info(dynamic message) => log(Level.info, message);
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
