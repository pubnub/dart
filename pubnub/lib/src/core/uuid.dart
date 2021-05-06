/// Represents an UUID.
///
/// {@category Basic Features}
class UUID {
  /// The actual value of an UUID.
  final String value;

  const UUID(this.value);

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
