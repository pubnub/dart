class Time {
  static final Time _time = Time._();

  Time._();
  factory Time() => _time;

  DateTime? _mockedTime;

  DateTime? now() {
    if (_mockedTime != null) {
      return _mockedTime;
    } else {
      return DateTime.now();
    }
  }

  static void mock(DateTime dateTime) {
    _time._mockedTime = dateTime;
  }

  static void unmock() {
    _time._mockedTime = null;
  }
}
