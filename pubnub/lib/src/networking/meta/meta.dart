import 'package:pubnub/core.dart';

import 'diagnostics.dart';

export 'strategy.dart';

Diagnostic? getNetworkDiagnostic(dynamic exception) {
  if (exception is RequestOtherException) {
    var otherException = exception.additionalData;
    var message = otherException.toString();

    return netDiagnosticsMap.entries.map((entry) {
      return entry.key.hasMatch(message)
          ? entry.value(entry.key.matchAsPrefix(message))
          : null;
    }).firstWhere((element) => element != null, orElse: () => null);
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

  return null;
}
