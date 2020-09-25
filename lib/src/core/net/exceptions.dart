import '../exceptions.dart';
import 'response.dart';

class PubNubRequestTimeoutException extends PubNubException {
  dynamic additionalData;

  PubNubRequestTimeoutException([this.additionalData])
      : super('request timed out');
}

class PubNubRequestCancelException extends PubNubException {
  dynamic additionalData;

  PubNubRequestCancelException([this.additionalData])
      : super('request cancelled');
}

class PubNubRequestOtherException extends PubNubException {
  dynamic additionalData;

  PubNubRequestOtherException([this.additionalData]) : super('request failed');
}

class PubNubRequestFailureException extends PubNubException {
  IResponse response;

  PubNubRequestFailureException(this.response)
      : super('request returned non-success status code');
}
