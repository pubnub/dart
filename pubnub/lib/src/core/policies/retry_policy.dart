import 'dart:math';

import 'package:pubnub/core.dart';

/// Retry policy represents a policy used when retrying a network operation.
///
/// Can be implemented to create custom retry policy.
abstract class RetryPolicy {
  /// Maximum retries in non-subscribe calls.
  final int maxRetries;

  const RetryPolicy(this.maxRetries);

  /// Returns a [Duration] that the SDK should wait before retrying.
  Duration getDelay(Fiber fiber);

  /// Linear retry policy. Useful for development.
  factory RetryPolicy.linear(
      {int? backoff, int? maxRetries, int? maximumDelay}) = LinearRetryPolicy;

  /// Exponential retry policy. Useful for production.
  factory RetryPolicy.exponential({int? maxRetries, int? maximumDelay}) =
      ExponentialRetryPolicy;
}

/// Linear retry policy.
///
/// Amount of delay between retries increases by fixed amount.
class LinearRetryPolicy extends RetryPolicy {
  /// Backoff amount in milliseconds
  final int backoff;

  /// Maximum amount of milliseconds to wait until retry is executed
  final int maximumDelay;

  const LinearRetryPolicy({int? backoff, int? maxRetries, int? maximumDelay})
      : backoff = backoff ?? 5,
        maximumDelay = maximumDelay ?? 60000,
        super(maxRetries ?? 5);

  @override
  Duration getDelay(Fiber fiber) {
    return Duration(
        milliseconds: (fiber.tries * backoff) + Random().nextInt(1000));
  }
}

/// Exponential retry policy.
///
/// Amount of delay between retries doubles up to the maximum amount.
class ExponentialRetryPolicy extends RetryPolicy {
  /// Maximum amount of milliseconds to wait until retry is executed
  final int maximumDelay;

  const ExponentialRetryPolicy({int? maxRetries, int? maximumDelay})
      : maximumDelay = maximumDelay ?? 60000,
        super(maxRetries ?? 5);

  @override
  Duration getDelay(Fiber fiber) {
    return Duration(
        milliseconds: min(maximumDelay,
            pow(2, fiber.tries - 1).toInt() * 1000 + Random().nextInt(1000)));
  }
}
