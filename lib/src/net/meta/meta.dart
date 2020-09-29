import 'package:pubnub/core.dart';

import 'diagnostics.dart';

export 'strategy.dart';
export 'retry_policy.dart';

Diagnostic getNetworkDiagnostic(dynamic exception) {
  if (exception is PubNubRequestOtherException ||
      exception is PubNubRequestTimeoutException) {
    var otherException = exception.additionalData;
    var message = otherException.toString();

    return netDiagnosticsMap.entries.map((entry) {
      return entry.key.hasMatch(message)
          ? entry.value(entry.key.matchAsPrefix(message))
          : null;
    }).firstWhere((element) => element != null, orElse: () => null);
  }

  return null;
}
