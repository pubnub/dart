import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:xml/xml.dart';
import 'package:pubnub/src/core/exceptions.dart' as core_exceptions;

PubNubException getExceptionFromAny(dynamic error, {int? statusCode}) {
  if (error is DefaultResult) {
    return getExceptionFromDefaultResult(error, statusCode: statusCode);
  }

  if (error is XmlDocument) {
    // handling the error for files
    var details = '';

    error.rootElement.childElements.forEach((element) {
      details += '${element.name}: ${element.innerText}\n';
    });

    return PubNubException('Request failed. Details: $details');
  }
  if (error is List) {
    if (error.isEmpty) {
      return UnknownException();
    } else if (error.length == 3) {
      return PublishException(error[1]);
    }
  }

  return PubNubException(
      'unknown exception${statusCode != null ? ' (status $statusCode)' : ''}: $error');
}

PubNubException getExceptionFromDefaultResult(DefaultResult result,
    {int? statusCode}) {
  if (result.status == 400 && result.message == 'Invalid Arguments') {
    return core_exceptions.InvalidArgumentsException();
  }

  if (result.status == 403 &&
      (result.message ?? '').startsWith('Use of the history Delete API')) {
    return MethodDisabledException(result.message!);
  }

  if (result.status == 403 &&
      (result.message == 'Forbidden' ||
          result.message == 'Token is expired.' ||
          result.message == 'Token is revoked.')) {
    return ForbiddenException(
        result.service ?? 'Access Manager', result.message ?? '');
  }

  // DataSync endpoints report failures as `{"errors": [{errorCode, message,
  // path}]}`, which `DefaultResult` keeps in `otherKeys`.
  var errors = result.otherKeys['errors'];
  if (errors is List && errors.isNotEmpty) {
    return DataSyncException.fromErrors(errors,
        statusCode: statusCode ?? result.status);
  }

  return PubNubException('${result.status} error: ${result.message}');
}
