import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:xml/xml.dart';

PubNubException getExceptionFromAny(dynamic error) {
  if (error is DefaultResult) {
    return getExceptionFromDefaultResult(error);
  }

  if (error is XmlDocument) {
    var details = error.rootElement.getElement('Message')?.text;

    return PubNubException(
        'Request to third party service failed. Details: $details');
  }
  if (error is List) {
    if (error.isEmpty) {
      return UnknownException();
    } else if (error.length == 3) {
      return PublishException(error[1]);
    }
  }

  return PubNubException('unknown exception: $error');
}

PubNubException getExceptionFromDefaultResult(DefaultResult result) {
  if (result.status == 400 && result.message == 'Invalid Arguments') {
    return InvalidArgumentsException();
  }

  if (result.status == 403 &&
      result.message!.startsWith('Use of the history Delete API')) {
    return MethodDisabledException(result.message!);
  }

  if (result.status == 403 &&
          (result.message == 'Forbidden' ||
              result.message == 'Token is expired.') ||
      (result.message == 'Token is revoked.')) {
    return ForbiddenException(result.service!, result.message ?? '');
  }

  return PubNubException('${result.status} error: ${result.message}');
}
