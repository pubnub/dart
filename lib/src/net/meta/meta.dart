import 'package:pubnub/pubnub.dart';

import 'diagnostics.dart';

export 'strategy.dart';
export 'retry_policy.dart';

Diagnostic getNetworkDiagnostic(dynamic exception) {
  if (exception is PubNubRequestOtherException ||
      exception is PubNubRequestTimeoutException) {
    var otherException = exception.additionalData;

    if (otherException?.message != null) {
      return netDiagnosticsMap.entries.map((entry) {
        return entry.key.hasMatch(otherException.message)
            ? entry.value(entry.key.matchAsPrefix(otherException.message))
            : null;
      }).firstWhere((element) => element != null, orElse: () => null);
    }
  }

  return null;
}
