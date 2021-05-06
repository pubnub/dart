import 'dart:async';

import 'package:pubnub/core.dart';

/// A record that contains logged information.
class LogRecord {
  /// Level of this log record.
  final int level;

  /// Message passed to the log method.
  final dynamic message;

  /// Scope of this.
  final String scope;

  /// Time at which this record was created.
  final DateTime time;

  /// Zone of the calling code.
  final Zone zone;

  /// Stack trace recorded when this record was created.
  ///
  /// May be null if stack trace recording is not turned on.
  final StackTrace? stackTrace;

  static int _counter = 0;

  final int id;

  LogRecord({
    required this.level,
    required this.message,
    required this.scope,
    this.stackTrace,
  })  : time = DateTime.now(),
        zone = Zone.current,
        id = _counter++;

  /// Returns a function that accepts a [LogRecord] and prints it using [customPrint] in given [format].
  ///
  /// [format] should be a raw string that otherwise would be a valid interpolation.
  /// You can refer to any property of [LogRecord] or some special properties:
  /// * `${level.name}` - this will return a string with a name associated with the level.
  ///
  /// ### Example
  /// ```
  /// var printer = LogRecord.createPrinter(r'$time: $message');
  ///
  /// logger.stream.listen(printer);
  /// ```
  static void Function(LogRecord) createPrinter(String format,
      {Function(String s) customPrint = print}) {
    return (LogRecord record) {
      var message = format
          .replaceAll(r'$time', record.time.toString())
          .replaceAll(r'$level', record.level.toString())
          .replaceAll(r'${level.name}', Level.getName(record.level))
          .replaceAll(r'$message', record.message.toString())
          .replaceAll(r'$scope', record.scope.toString())
          .replaceAll(r'$stackTrace', record.stackTrace.toString())
          .replaceAll(r'$zone', record.zone.toString())
          .replaceAll(r'$id', record.id.toString());

      customPrint(message);
    };
  }

  /// Function that can be passed into `listen` method to print a [LogRecord].
  ///
  /// Prints `[$time] (${level.name}) $message`.
  static void Function(LogRecord) defaultPrinter =
      LogRecord.createPrinter(r'[$time] (${level.name}) $scope: $message');
}

/// A logger implementation that contains a stream of [LogRecord] records.
///
/// This is a hierarchical logger:
/// - loggers are arranged in a tree structure,
/// - the logger that you pass into the `provideLogger` function is called the **root** node,
/// - any logger that is contained inside the **root** node (or any of its children, etc.) is a **leaf** node,
/// - each logger has a [stream] property that contains records logged to it or any of its children.
///
/// To access the *root* logger, pass `null` in `injectLogger` method.
///
/// To access any *leaf* logger, pass a dot-separated String in `injectLogger` method.
///
///
/// ### Example
/// ```
/// var root = StreamLogger.root('myLogger');
///
/// provideLogger(root, () {
///   var child = injectLogger('parent.child');
///
///   child.info('My log message');
/// });
/// ```
/// In the example above, the structure of the loggers will resemble this:
/// * **root** logger named `myLogger`
///     * logger named `parent`
///         * logger named `child`
class StreamLogger extends ILogger {
  /// Name of this logger.
  final String name;
  final StreamLogger? _parent;

  int? _logLevel;

  final StreamController<LogRecord> _streamController =
      StreamController.broadcast(sync: true);

  final Map<String, StreamLogger> _children = {};

  final bool _recordStackTraces;

  StreamLogger._(this.name, this._parent,
      {bool recordStackTraces = false, int logLevel = 10000})
      : _recordStackTraces = recordStackTraces,
        _logLevel = logLevel;

  /// Creates a root logger.
  ///
  /// If [recordStackTraces] is true, log records will contain the stack trace of the calling code.
  /// [logLevel] should be an integer between `0` and `10000`. Please refer to [Level] for more information.
  StreamLogger.root(String name,
      {bool recordStackTraces = false, int logLevel = 10000})
      : this._(name, null,
            recordStackTraces: recordStackTraces, logLevel: logLevel);

  /// Broadcast stream of log records.
  Stream<LogRecord> get stream => _streamController.stream;
  StreamSink<LogRecord> get _sink => _streamController.sink;

  /// Whether the logger records stack traces.
  bool get recordStackTraces {
    if (isRoot) {
      return _recordStackTraces;
    } else {
      return _root._recordStackTraces;
    }
  }

  /// Log level of this logger.
  int get logLevel {
    if (_logLevel == null) {
      return _root._logLevel!;
    } else {
      return _logLevel!;
    }
  }

  set logLevel(int level) {
    _logLevel = level;
  }

  StreamLogger get _root {
    var current = this;

    while (!current.isRoot) {
      current = current._parent!;
    }

    return current;
  }

  /// Whether its a root node in the hierarchy.
  bool get isRoot {
    return _parent == null;
  }

  StreamLogger _scopedTo(List<String> scope) {
    if (scope.isEmpty) {
      return this;
    }

    var childName = scope.first;
    var child = _createOrGet(childName);

    return child._scopedTo(scope.sublist(1));
  }

  StreamLogger _createOrGet(String childName) {
    if (!_children.containsKey(childName)) {
      var child = StreamLogger._(childName, this);

      child.stream.listen((record) {
        _streamController.add(record);
      });

      _children[childName] = child;
    }

    return _children[childName]!;
  }

  /// Returns full name of this logger.
  ///
  /// This name will be a dot-separated string that uniquely identifies this logger.
  String get fullName => !isRoot ? '${_parent!.fullName}.$name' : name;

  /// Creates or retrieves a logger that exists under this node.
  @override
  StreamLogger get(String? id) {
    if (id == null) {
      return this;
    }

    var segments = id.split('.');

    return _scopedTo(segments);
  }

  /// Create a new log record in this logger.
  @override
  void log(int level, message) {
    if (level <= logLevel) {
      StackTrace? stackTrace;

      if (recordStackTraces) {
        stackTrace = StackTrace.current;
      }

      var record = LogRecord(
          message: message,
          level: level,
          scope: fullName,
          stackTrace: stackTrace);

      _sink.add(record);
    }
  }

  bool _isDisposed = false;

  Future<void> dispose() async {
    if (!_isDisposed) {
      await _streamController.close();

      for (var child in _children.values) {
        await child.dispose();
      }

      _isDisposed = true;
    }
  }
}
