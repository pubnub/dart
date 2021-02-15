import 'package:test/test.dart';

import 'package:pubnub/core.dart';

class FakeLogger extends ILogger {
  List<String> messages = [];

  @override
  void log(int level, message) {
    messages.add(message);
  }

  @override
  ILogger get(String scope) => this;
}

void main() {
  group('Logging', () {
    group('[injectLogger]', () {
      test('should return the logger from Zone.current', () async {
        var logger = FakeLogger();

        await provideLogger(logger, () async {
          var logger = injectLogger('test.logger');

          logger.info('test');
        });

        expect(logger.messages, equals(['test']));
      });

      test('should return the DummyLogger if run without provideLogger', () {
        var lazyLogger = injectLogger('some.scope');

        expect(lazyLogger.logger, isA<DummyLogger>());

        expect(() {
          lazyLogger.info('ignored message');
        }, returnsNormally);
      });
    });
  });
}
