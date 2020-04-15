/// Class representing an UUID.
class UUID {
  /// The actual value of an UUID.
  final String value;

  /// Some state that may be associated with this UUID. It is used
  /// in certain contexts.
  final Map<String, dynamic> state;

  const UUID(this.value, {this.state = null});

  @override
  String toString() => '$value';
}
