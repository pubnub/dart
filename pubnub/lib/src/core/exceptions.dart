/// An exception thrown by the PubNub SDK.
///
/// {@category Exceptions}
class PubNubException implements Exception {
  final String message;
  final StackTrace stackTrace;

  PubNubException(this.message, [StackTrace? stackTrace])
      : stackTrace = stackTrace ?? StackTrace.current;

  @override
  String toString() {
    return '$runtimeType: $message\n$stackTrace';
  }
}

/// An exception that happens during keyset creation or resolution.
///
/// {@category Exceptions}
class KeysetException extends PubNubException {
  KeysetException(String message) : super(message);
}

/// An exception thrown when a disabled API has been requested.
///
/// {@category Exceptions}
class MethodDisabledException extends PubNubException {
  MethodDisabledException(String message) : super(message);
}

/// An exception thrown when some argument is invalid.
///
/// This may be due to:
/// - an invalid subscribe key.
/// - missing or invalid timetoken or channelsTimetoken (values must be greater than 0).
/// - mismatched number of channels and timetokens.
/// - invalid characters in a channel name.
/// - other invalid request data.
///
/// {@category Exceptions}
class InvalidArgumentsException extends PubNubException {
  static final String _message = '''Invalid Arguments. This may be due to:
  - an invalid subscribe key,
  - missing or invalid timetoken or channelsTimetoken (values must be greater than 0),
  - mismatched number of channels and timetokens,
  - invalid characters in a channel name,
  - other invalid request data.''';

  InvalidArgumentsException() : super(_message);
}

/// An exception thrown when something unexpected happens in the SDK.
///
/// {@category Exceptions}
class UnknownException extends PubNubException {
  static final String _message = 'An unknown error has occurred';

  UnknownException() : super(_message);
}

/// An exception thrown when the API has returned an unexpected response.
///
/// {@category Exceptions}
class MalformedResponseException extends PubNubException {
  static final String _message =
      'Endpoint has returned unforeseen or malformed response';

  MalformedResponseException() : super(_message);
}

/// An exception thrown when a method is not yet implemented.
///
/// {@category Exceptions}
class NotImplementedException extends PubNubException {
  static final String _message = 'This feature is not yet implemented';

  NotImplementedException() : super(_message);
}

/// An exception thrown when publish fails.
///
/// {@category Exceptions}
class PublishException extends PubNubException {
  PublishException(String message) : super(message);
}

/// An exception thrown when maximum amount of retries has been reached.
///
/// {@category Exceptions}
class MaximumRetriesException extends PubNubException {
  static final String _message = 'Maximum number of retries has been reached.';

  MaximumRetriesException() : super(_message);
}

/// An exception thrown when a feature is not available for particular keyset.
///
/// {@category Exceptions}
class ForbiddenException extends PubNubException {
  final String service;
  final String reason;

  ForbiddenException(this.service, this.reason)
      : super('Forbidden error, with deatils: $reason');
}

/// An exception thrown when a DataSync endpoint returns an error.
///
/// It describes the first error reported by the server. When the server
/// reports several errors, all of them are available in [errors].
///
/// {@category Exceptions}
class DataSyncException extends PubNubException {
  /// Error code used when the server does not report one.
  static const unknownErrorCode = 'unknown';

  /// Machine-readable error code, for example `DS-0100`.
  ///
  /// It is stable across releases — branch on it instead of on
  /// [errorMessage]. It is [unknownErrorCode] when the server does not report
  /// a code.
  final String errorCode;

  /// Human-readable description of the error, intended for logs and
  /// diagnostics. It is not stable across releases.
  final String errorMessage;

  /// Location of the input that caused the error, when the server can
  /// identify one.
  final String? path;

  /// HTTP status code of the failed request, when known.
  final int? statusCode;

  final List<DataSyncException> _otherErrors;

  /// Every error reported by the server for the request.
  ///
  /// It is never empty and its first item is this exception.
  List<DataSyncException> get errors =>
      List.unmodifiable([this, ..._otherErrors]);

  /// Creates an exception for the [errorCode] error. [otherErrors] are the
  /// further errors reported for the same request.
  DataSyncException(this.errorCode, this.errorMessage,
      {this.path,
      this.statusCode,
      List<DataSyncException> otherErrors = const []})
      : _otherErrors = List.unmodifiable(otherErrors),
        super('DataSync request failed'
            '${statusCode != null ? ' with status $statusCode' : ''}. '
            '${[
          _describe(errorCode, errorMessage, path),
          for (var other in otherErrors)
            _describe(other.errorCode, other.errorMessage, other.path)
        ].join('; ')}');

  /// Creates the exception out of the `errors` array of a DataSync response.
  ///
  /// @nodoc
  factory DataSyncException.fromErrors(List<dynamic> items, {int? statusCode}) {
    var parsed = [
      for (var item in items) _parse(item, statusCode),
      if (items.isEmpty)
        DataSyncException(unknownErrorCode, '', statusCode: statusCode),
    ];

    var first = parsed.first;
    return DataSyncException(first.errorCode, first.errorMessage,
        path: first.path,
        statusCode: statusCode,
        otherErrors: parsed.sublist(1));
  }

  static DataSyncException _parse(dynamic item, int? statusCode) {
    if (item is! Map) {
      return DataSyncException(unknownErrorCode, '$item',
          statusCode: statusCode);
    }

    var errorCode = item['errorCode'];
    var errorMessage = item['message'];
    var path = item['path'];

    return DataSyncException(
        errorCode != null ? '$errorCode' : unknownErrorCode,
        errorMessage != null ? '$errorMessage' : '',
        path: path != null ? '$path' : null,
        statusCode: statusCode);
  }

  static String _describe(
          String errorCode, String errorMessage, String? path) =>
      '$errorCode: $errorMessage${path != null ? ' (at $path)' : ''}';
}
