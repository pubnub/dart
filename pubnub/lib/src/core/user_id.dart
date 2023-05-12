/// Represents an UserID.
///
/// {@category Basic Features}
class UserId {
  /// The actual value of an UserId.
  final String value;

  const UserId(this.value);

  @override
  String toString() => '$value';

  @override
  bool operator ==(dynamic other) {
    if (other is UserId) {
      return value == other.value;
    }

    return false;
  }
}
