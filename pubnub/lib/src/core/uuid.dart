/// Represents an UUID.
///
/// {@category Basic Features}
class UUID {
  /// The actual value of an UUID.
  final String value;

  /// State that may be associated with this UUID. It is used
  /// in certain contexts.
  final Map<String, dynamic> state;

  const UUID(this.value, {this.state});

  @override
  String toString() => '$value';

  @override
  bool operator ==(dynamic other) {
    if (other is UUID) {
      return value == other.value;
    }

    return false;
  }
}
