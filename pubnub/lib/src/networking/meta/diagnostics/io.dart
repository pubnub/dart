import 'dart:io';
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
  const AccessDeniedDiagnostic();
}

Diagnostic? getNetworkDiagnostic(dynamic exception) {
  if (exception is RequestOtherException) {
    var originalException = exception.additionalData;

    if (originalException is SocketException) {
      if (originalException.osError?.message ==
          'nodename nor servname provided, or not known') {
        return HostLookupFailedDiagnostic(originalException);
      }

      var errno = _getErrorCode(originalException.osError?.errorCode);

      switch (errno) {
        case _Errno.ECONNRESET:
        case _Errno.ECONNABORTED:
        case _Errno.ECONNREFUSED:
        case _Errno.ETIMEOUT:
        case _Errno.EHOSTUNREACH:
          return HostIsDownDiagnostic(originalException);
        case _Errno.EBADF:
        case _Errno.ENETUNREACH:
        case _Errno.unknown:
          return UnknownHttpExceptionDiagnostic(originalException);
      }
    }

    if (originalException is HttpException ||
        originalException is HandshakeException) {
      return UnknownHttpExceptionDiagnostic(originalException);
    }
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

enum _Errno {
  unknown,
  ECONNABORTED,
  ECONNRESET,
  ECONNREFUSED,
  EHOSTUNREACH,
  EBADF,
  ETIMEOUT,
  ENETUNREACH
}

_Errno _getErrorCode(int? errno) {
  if (errno == null) {
    return _Errno.unknown;
  }

  if (Platform.isLinux) {
    return _linuxErrnoCodes[errno] ?? _Errno.unknown;
  } else if (Platform.isWindows) {
    return _winErrnoCodes[errno] ?? _Errno.unknown;
  } else if (Platform.isMacOS || Platform.isIOS) {
    return _macErrnoCodes[errno] ?? _Errno.unknown;
  } else if (Platform.isAndroid) {
    return _androidErrnoCodes[errno] ?? _Errno.unknown;
  } else {
    return _Errno.unknown;
  }
}

const _linuxErrnoCodes = {
  9: _Errno.EBADF,
  101: _Errno.ENETUNREACH,
  103: _Errno.ECONNABORTED,
  104: _Errno.ECONNRESET,
  110: _Errno.ETIMEOUT,
  111: _Errno.ECONNREFUSED,
  113: _Errno.EHOSTUNREACH,
};

const _winErrnoCodes = {
  9: _Errno.EBADF,
  106: _Errno.ECONNABORTED,
  107: _Errno.ECONNREFUSED,
  108: _Errno.ECONNRESET,
  110: _Errno.EHOSTUNREACH,
  118: _Errno.ENETUNREACH,
  138: _Errno.ETIMEOUT
};

const _macErrnoCodes = {
  9: _Errno.EBADF,
  51: _Errno.ENETUNREACH,
  53: _Errno.ECONNABORTED,
  54: _Errno.ECONNRESET,
  60: _Errno.ETIMEOUT,
  61: _Errno.ECONNREFUSED,
  65: _Errno.EHOSTUNREACH
};

const _androidErrnoCodes = {
  9: _Errno.EBADF,
  111: _Errno.ECONNREFUSED,
  113: _Errno.ECONNABORTED,
  114: _Errno.ENETUNREACH,
  116: _Errno.ETIMEOUT,
  118: _Errno.EHOSTUNREACH
};
