import 'package:pubnub/core.dart';

class TestLogger extends ILogger {
  final String id;
  final bool debug;

  TestLogger(this.id, {this.debug = false});

  int get _level => debug ? Level.all : Level.warning;

  @override
  ILogger get(String id) {
    return TestLogger(id, debug: debug);
  }

  @override
  void log(int level, message) {
    if (level <= _level) {
      print('[$id] (${DateTime.now().toIso8601String()}) $message');
    }
  }
}
