class MockServerException implements Exception {
  final String message;

  MockServerException(this.message);

  @override
  String toString() => 'MockServerException: $message';
}
