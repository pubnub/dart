import 'logging.dart';

class DummyLogger extends ILogger {
  @override
  DummyLogger get(String scope) => this;

  @override
  void log(int level, message) {}
}
