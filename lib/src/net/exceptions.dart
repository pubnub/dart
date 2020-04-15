import 'package:pubnub/src/core/exceptions.dart';

class PubNubRequestTimeoutException extends PubNubException {}

class PubNubRequestCancelException extends PubNubException {
  dynamic additionalData;
  PubNubRequestCancelException([this.additionalData]);
}

class PubNubRequestOtherException extends PubNubException {
  dynamic additionalData;
  PubNubRequestOtherException([this.additionalData]);
}

class PubNubRequestFailureException extends PubNubException {
  dynamic responseData;
  PubNubRequestFailureException(this.responseData);
}
