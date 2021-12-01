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
      : super('Forbidden because $reason');
}
