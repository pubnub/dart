import 'package:pubnub/src/core/exceptions.dart';

class PubNubRequestTimeoutException extends PubNubException {
  PubNubRequestTimeoutException() : super('request timed out');
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
  dynamic responseData;
  PubNubRequestFailureException(this.responseData) : super('request failed');
}
