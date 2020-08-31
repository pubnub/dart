class PubNubException implements Exception {
  String message;
  StackTrace stackTrace;

  PubNubException(this.message) {
    stackTrace = StackTrace.current;
  }

  @override
  String toString() {
    return 'PubNubException: $message\n${stackTrace.toString()} ';
  }
}

class MethodDisabledException extends PubNubException {
  MethodDisabledException(String message) : super(message);
}

class InvalidArgumentsException extends PubNubException {
  static final String _message = '''Invalid Arguments. This may be due to:
  - an invalid subscribe key,
  - missing or invalid timetoken or channelsTimetoken (values must be greater than 0),
  - mismatched number of channels and timetokens,
  - invalid characters in a channel name,
  - other invalid request data.''';

  InvalidArgumentsException() : super(_message);
}

class UnknownException extends PubNubException {
  static final String _message = 'An unknown error has occurred';

  UnknownException() : super(_message);
}

class MalformedResponseException extends PubNubException {
  static final String _message =
      'Endpoint has returned unforeseen or malformed response';

  MalformedResponseException() : super(_message);
}

class NotImplementedException extends PubNubException {
  static final String _message = 'This feature is not yet implemented';

  NotImplementedException() : super(_message);
}

class PublishException extends PubNubException {
  PublishException(String message) : super(message);
}

class MaximumRetriesException extends PubNubException {
  static final String _message = 'Maximum number of retries has been reached.';

  MaximumRetriesException() : super(_message);
}
