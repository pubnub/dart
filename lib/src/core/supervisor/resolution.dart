abstract class Resolution {
  const Resolution();

  factory Resolution.fail() => FailResolution();
  factory Resolution.delay(Duration delay) => DelayResolution(delay);
  factory Resolution.retry() => RetryResolution();
  factory Resolution.networkStatus(bool isUp) => NetworkStatusResolution(isUp);
}

class FailResolution extends Resolution {}

class DelayResolution extends Resolution {
  final Duration delay;

  const DelayResolution(this.delay);
}

class RetryResolution extends Resolution {}

class NetworkStatusResolution extends Resolution {
  final bool isUp;

  const NetworkStatusResolution(this.isUp);
}
