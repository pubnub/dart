import 'endpoint.dart';

/// Represents a timetoken value returned and required by most PubNub APIs.
///
/// {@category Basic Features}
class Timetoken implements Result {
  /// The actual value of the Timetoken. It's a number of nanoseconds since the epoch.
  final BigInt value;

  const Timetoken(this.value);

  /// Returns a string representation of this Timetoken.
  @override
  String toString() => '$value';

  /// Timetokens are compared based on their [value].
  @override
  bool operator ==(dynamic other) {
    if (other is Timetoken) {
      return value == other.value;
    } else {
      return value == other;
    }
  }

  /// Converts Timetoken to a [DateTime].
  ///
  /// Beware, as it drops the granularity to microseconds.
  DateTime toDateTime() {
    return DateTime.fromMicrosecondsSinceEpoch(
        (value / BigInt.from(10)).round());
  }

  /// Creates a Timetoken from [DateTime].
  ///
  /// Beware, as the maximum granularity of the timestamp obtained this
  /// way is a microsecond.
  factory Timetoken.fromDateTime(DateTime dateTime) {
    return Timetoken(BigInt.from(dateTime.microsecondsSinceEpoch * 10));
  }
}

/// @nodoc
extension TimetokenDateTimeExtentions on DateTime {
  /// Convert DateTime to Timetoken.
  Timetoken toTimetoken() {
    return Timetoken.fromDateTime(this);
  }
}
