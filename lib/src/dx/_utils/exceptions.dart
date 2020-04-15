import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

PubNubException getExceptionFromAny(dynamic error) {
  if (error is DefaultResult) {
    return getExceptionFromDefaultResult(error);
  }

  if (error is List) {
    if (error.length == 0) {
      return UnknownException();
    }
  }

  return PubNubException();
}

PubNubException getExceptionFromDefaultResult(DefaultResult result) {
  if (result.status == 400 && result.message == 'Invalid Arguments') {
    return InvalidArgumentsException();
  }

  if (result.status == 403 &&
      result.message.startsWith('Use of the history Delete API')) {
    return MethodDisabledException(result.message);
  }

  print('${result.status} error: ${result.message}');
  return PubNubException();
}
