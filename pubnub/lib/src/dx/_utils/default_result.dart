import 'package:pubnub/core.dart';

class DefaultResult extends Result {
  int? status;
  bool? isError;
  String? service;
  String? _message;
  String? _errorMessage;
  Map<String, dynamic>? _errorDetails;

  String? get message => _errorMessage ?? _message;
  Map<String, dynamic>? get error => _errorDetails;

  Map<String, dynamic> otherKeys = {};

  DefaultResult();

  static Map<String, dynamic> collectOtherKeys(
      dynamic object, List<String> knownKeys) {
    var clone = Map<String, dynamic>.from(object);

    for (var key in knownKeys) {
      clone.remove(key);
    }
    return clone;
  }

  factory DefaultResult.fromJson(dynamic object) {
    var hasError = false;
    var errorMessage;
    var errorDetails;

    if (object['error'] is Map<String, dynamic>) {
      hasError = true;
      errorDetails = object['error'];
      errorMessage = errorDetails['message'];
      if (errorDetails['details'] != null) {
        (errorDetails['details'] as List).forEach((e) => errorMessage +=
            '\n Error Details: ${e['message']} for ${e['location']} in ${e['locationType']} of ${errorDetails['source']} api from ${object['service']}');
      }
    } else if (object['error'] is bool) {
      hasError = object['error'] as bool;
      errorMessage = object['error_message'];
    } else if (object['error'] is String) {
      hasError = true;
      errorMessage = object['error'];
    }

    return DefaultResult()
      ..status = object['status'] as int?
      ..isError = hasError
      ..service = object['service'] as String?
      .._errorDetails = errorDetails
      .._message = object['message'] as String?
      .._errorMessage = errorMessage
      ..otherKeys = collectOtherKeys(
          object, ['status', 'error', 'message', 'error_message', 'service']);
  }
}
