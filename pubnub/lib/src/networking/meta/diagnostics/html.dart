import 'package:pubnub/core.dart';

class HostIsDownDiagnostic extends Diagnostic {
  final dynamic originalException;

  const HostIsDownDiagnostic(this.originalException);
}

class HostLookupFailedDiagnostic extends Diagnostic {
  final dynamic originalException;

  const HostLookupFailedDiagnostic(this.originalException);
}

class UnknownHttpExceptionDiagnostic extends Diagnostic {
  final dynamic originalException;

  const UnknownHttpExceptionDiagnostic(this.originalException);
}

class TimeoutDiagnostic extends Diagnostic {
  const TimeoutDiagnostic();
}

class AccessDeniedDiagnostic extends Diagnostic {
  AccessDeniedDiagnostic();
}

Diagnostic? getNetworkDiagnostic(dynamic exception) {
  if (exception is RequestOtherException) {
    return UnknownHttpExceptionDiagnostic(exception);
  }

  if (exception is RequestTimeoutException) {
    return TimeoutDiagnostic();
  }

  if (exception is RequestFailureException) {
    var request = exception.response;

    if (request.statusCode == 403) {
      return AccessDeniedDiagnostic();
    }
  }
}
