import 'endpoint.dart';

/// Class representing a Timetoken value returned and required by most PubNub APIs.
class Timetoken implements Result {
  /// The actual value of the Timetoken. It's a number of nanoseconds since the epoch.
  final int value;

  const Timetoken(this.value);

  @override
  String toString() => '$value';

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
  /// Beware, as it drops the granurality to microseconds.
  DateTime toDateTime() {
    return DateTime.fromMicrosecondsSinceEpoch((value / 10).round());
  }

  /// Creates a Timetoken from [DateTime].
  ///
  /// Beware, as the maximum granurality of the timestamp obtained this
  /// way is a microsecond.
  factory Timetoken.fromDateTime(DateTime dateTime) {
    return Timetoken(dateTime.microsecondsSinceEpoch * 10);
  }
}

extension TimetokenDateTimeExtentions on DateTime {
  /// Convert DateTime to Timetoken.
  Timetoken toTimetoken() {
    return Timetoken.fromDateTime(this);
  }
}
