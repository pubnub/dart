import 'package:pubnub/core.dart';

import 'diagnostics/diagnostics.dart';

/// @nodoc
class NetworkingStrategy extends Strategy {
  final RetryPolicy? retryPolicy;

  NetworkingStrategy({this.retryPolicy});

  @override
  List<Resolution>? resolve(Fiber fiber, Diagnostic diagnostic) {
    if (!fiber.isSubscribe) {
      return [Resolution.fail()];
    }

    // For subscribe requests, check retry policy configuration
    if (retryPolicy == null || retryPolicy is NoneRetryPolicy) {
      // No retry policy or explicitly set to none means no retries
      return [Resolution.fail()];
    }

    // Subscribe requests with retry policy enabled
    if (diagnostic is HostIsDownDiagnostic ||
        diagnostic is HostLookupFailedDiagnostic ||
        diagnostic is TimeoutDiagnostic ||
        diagnostic is UnknownHttpExceptionDiagnostic) {
      // Check if we've exceeded max retries
      if (diagnostic is! TimeoutDiagnostic &&
          fiber.tries >= retryPolicy!.maxRetries) {
        return [Resolution.fail()];
      }

      // Apply retry with delay based on the retry policy
      return [
        Resolution.networkStatus(false),
        Resolution.delay(retryPolicy!.getDelay(fiber)),
        Resolution.retry()
      ];
    }

    return null;
  }
}
