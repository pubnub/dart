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
          {int backoff = 5, int maxRetries = 5, int maximumDelay = 60000}) =>
      LinearRetryPolicy(
          backoff: backoff, maxRetries: maxRetries, maximumDelay: maximumDelay);

  /// Exponential retry policy. Useful for production.
  factory RetryPolicy.exponential(
          {int maxRetries = 5, int maximumDelay = 60000}) =>
      ExponentialRetryPolicy(
          maxRetries: maxRetries, maximumDelay: maximumDelay);
}

/// Linear retry policy.
///
/// Amount of delay between retries increases by fixed amount.
class LinearRetryPolicy extends RetryPolicy {
  /// Backoff amount in milliseconds
  final int backoff;

  /// Maximum amount of milliseconds to wait until retry is executed
  final int maximumDelay;

  const LinearRetryPolicy({this.backoff, int maxRetries, this.maximumDelay})
      : super(maxRetries);

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

  const ExponentialRetryPolicy({int maxRetries, this.maximumDelay})
      : super(maxRetries);

  @override
  Duration getDelay(Fiber fiber) {
    return Duration(
        milliseconds: min(maximumDelay,
            pow(2, fiber.tries - 1) * 1000 + Random().nextInt(1000)));
  }
}
