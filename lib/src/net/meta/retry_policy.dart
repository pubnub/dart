import 'dart:math';

import 'package:pubnub/pubnub.dart';

abstract class RetryPolicy {
  final int maxRetries;

  const RetryPolicy(this.maxRetries);

  Duration getDelay(Fiber fiber);

  factory RetryPolicy.linear({int backoff, int maxRetries = 5}) =>
      LinearRetryPolicy(backoff: backoff, maxRetries: maxRetries);
  factory RetryPolicy.exponential({int maxRetries = 5}) =>
      ExponentialRetryPolicy(maxRetries: maxRetries);
}

class LinearRetryPolicy extends RetryPolicy {
  final int backoff;

  const LinearRetryPolicy({this.backoff, int maxRetries}) : super(maxRetries);

  @override
  Duration getDelay(Fiber fiber) {
    return Duration(
        milliseconds: (fiber.tries * backoff) + Random().nextInt(1000));
  }
}

class ExponentialRetryPolicy extends RetryPolicy {
  const ExponentialRetryPolicy({int maxRetries}) : super(maxRetries);

  @override
  Duration getDelay(Fiber fiber) {
    return Duration(
        milliseconds: pow(2, fiber.tries - 1) * 1000 + Random().nextInt(1000));
  }
}
