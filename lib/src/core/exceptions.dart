class PubNubException implements Exception {
  String message;
  StackTrace stackTrace;

  PubNubException() {
    stackTrace = StackTrace.current;
  }

  String toString() {
    return "PubNubException: $message\n${stackTrace.toString()} ";
  }
}

class MethodDisabledException extends PubNubException {
  String message;

  MethodDisabledException(this.message);
}

class InvalidArgumentsException extends PubNubException {
  String message = '''Invalid Arguments. This may be due to:
  - an invalid subscribe key,
  - missing or invalid timetoken or channelsTimetoken (values must be greater than 0),
  - mismatched number of channels and timetokens,
  - invalid characters in a channel name,
  - other invalid request data.''';

  InvalidArgumentsException();
}

class UnknownException extends PubNubException {
  String message = "An unknown error has occurred";

  UnknownException();
}

class MalformedResponseException extends PubNubException {
  String message = "Endpoint has returned unforeseen or malformed response";

  MalformedResponseException();
}

class NotImplementedException extends PubNubException {
  String message = "This feature is not yet implemented";

  NotImplementedException();
}
