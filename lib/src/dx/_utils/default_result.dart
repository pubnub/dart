import 'package:pubnub/src/core/core.dart';

class DefaultResult extends Result {
  int status;
  bool isError;
  String service;
  String _message;
  String _errorMessage;

  String get message => _message ?? _errorMessage;

  Map<String, dynamic> otherKeys = {};

  DefaultResult();

  static Map<String, dynamic> collectOtherKeys(
      dynamic object, List<String> knownKeys) {
    Map<String, dynamic> clone = Map.from(object);

    for (var key in knownKeys) {
      clone.remove(key);
    }
    return clone;
  }

  factory DefaultResult.fromJson(dynamic object) => DefaultResult()
    ..status = object['status'] as int
    ..service = object['service'] as String
    ..isError = object['error'] as bool
    .._message = object['message'] as String
    .._errorMessage = object['error_message'] as String
    ..otherKeys = collectOtherKeys(
        object, ['status', 'error', 'message', 'error_message', 'service']);
}

class DefaultObjectResult extends Result {
  dynamic status;
  Map<String, dynamic> error;
  dynamic data;
  Map<String, dynamic> otherKeys = {};

  DefaultObjectResult._();

  static Map<String, dynamic> collectOtherKeys(
      dynamic object, List<String> knownKeys) {
    Map<String, dynamic> clone = Map.from(object);
    for (var key in knownKeys) {
      clone.remove(key);
    }
    return clone;
  }

  factory DefaultObjectResult.fromJson(dynamic object) =>
      DefaultObjectResult._()
        ..status = object['status']
        ..data = object['data']
        ..error = object['error'] as Map<String, dynamic> ?? {}
        ..otherKeys = collectOtherKeys(object, ['status', 'error', 'data']);
}
