import 'package:pubnub/core.dart';

import 'diagnostics.dart';

export 'strategy.dart';

Diagnostic getNetworkDiagnostic(dynamic exception) {
  if (exception is PubNubRequestOtherException) {
    var otherException = exception.additionalData;
    var message = otherException.toString();

    return netDiagnosticsMap.entries.map((entry) {
      return entry.key.hasMatch(message)
          ? entry.value(entry.key.matchAsPrefix(message))
          : null;
    }).firstWhere((element) => element != null, orElse: () => null);
  }

  if (exception is PubNubRequestTimeoutException) {
    return TimeoutDiagnostic();
  }

  if (exception is PubNubRequestFailureException) {
    var request = exception.response;

    if (request.statusCode == 403) {
      return AccessDeniedDiagnostic();
    }
  }

  return null;
}
