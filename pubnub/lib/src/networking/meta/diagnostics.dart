import 'package:pubnub/core.dart';

class HostIsDownDiagnostic extends Diagnostic {
  final String host;
  final int port;

  const HostIsDownDiagnostic(this.host, this.port);
}

class HostLookupFailedDiagnostic extends Diagnostic {
  final String host;

  const HostLookupFailedDiagnostic(this.host);
}

class UnknownHttpExceptionDiagnostic extends Diagnostic {
  const UnknownHttpExceptionDiagnostic();
}

class TimeoutDiagnostic extends Diagnostic {
  const TimeoutDiagnostic();
}

final Map<RegExp, Diagnostic Function(Match)> netDiagnosticsMap = {
  RegExp(r'^SocketException: OS Error: Software caused connection abort, errno = 103, address = ([a-zA-Z0-9\-\.]+), port = ([0-9]+)$'):
      (match) =>
          HostIsDownDiagnostic(match.group(1), int.parse(match.group(2))),
  RegExp(r'^SocketException: Connection failed \(OS Error: Host is down, errno = 64\), address = ([a-zA-Z0-9\-\.]+), port = ([0-9]+)$'):
      (match) =>
          HostIsDownDiagnostic(match.group(1), int.parse(match.group(2))),
  RegExp(r"^SocketException: Failed host lookup: '([a-zA-Z0-9\-\.]+)'"):
      (match) => HostLookupFailedDiagnostic(match.group(1)),
  RegExp(r"^Failed host lookup: '([a-zA-Z0-9\-\.]+)'$"): (match) =>
      HostLookupFailedDiagnostic(match.group(1)),
  RegExp(r'^Connecting timed out'): (match) => UnknownHttpExceptionDiagnostic(),
  RegExp(r'^HttpException: , uri ='): (match) =>
      UnknownHttpExceptionDiagnostic(),
};

class AccessDeniedDiagnostic extends Diagnostic {
  Set<String> affectedChannels = {};

  AccessDeniedDiagnostic();
}
