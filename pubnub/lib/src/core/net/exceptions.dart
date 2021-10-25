import '../exceptions.dart';
import 'response.dart';

class RequestTimeoutException extends PubNubException {
  final dynamic? additionalData;

  RequestTimeoutException([this.additionalData]) : super('request timed out');
}

class RequestCancelException extends PubNubException {
  final dynamic? additionalData;

  RequestCancelException([this.additionalData]) : super('request cancelled');
}

class RequestOtherException extends PubNubException {
  final dynamic? additionalData;

  RequestOtherException([this.additionalData])
      : super('request failed ($additionalData)');
}

class RequestFailureException extends PubNubException {
  final IResponse response;
  final int? statusCode;

  RequestFailureException(this.response, {this.statusCode})
      : super('request returned non-success status code: $statusCode');
}
