import 'package:pubnub/core.dart';

import 'diagnostics/diagnostics.dart';

/// @nodoc
class NetworkingStrategy extends Strategy {
  final RetryPolicy? retryPolicy;

  NetworkingStrategy({this.retryPolicy});

  @override
  List<Resolution>? resolve(Fiber fiber, Diagnostic diagnostic) {
    if (diagnostic is TimeoutDiagnostic && fiber.isSubscribe) {
      return [Resolution.retry()];
    }

    if (retryPolicy == null) {
      return [Resolution.fail()];
    }

    if (!fiber.isSubscribe && fiber.tries >= (retryPolicy!.maxRetries)) {
      return [Resolution.fail()];
    }

    if (diagnostic is HostIsDownDiagnostic ||
        diagnostic is HostLookupFailedDiagnostic ||
        diagnostic is TimeoutDiagnostic ||
        diagnostic is UnknownHttpExceptionDiagnostic) {
      // Host is down. We should retry after some delay.

      return [
        Resolution.networkStatus(false),
        Resolution.delay(retryPolicy!.getDelay(fiber)),
        Resolution.retry()
      ];
    }

    return null;
  }
}
