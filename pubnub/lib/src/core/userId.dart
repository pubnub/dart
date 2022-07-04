/// Represents an userId.
///
/// {@category Basic Features}
class UserId {
  /// The  value of an UUID.
  final String value;

  const UserId(this.value);

  @override
  String toString() => '$value';

  @override
  bool operator ==(Object argument) {
    if (argument is UserId) {
      return value == argument.value;
    }

    return false;
  }
}
