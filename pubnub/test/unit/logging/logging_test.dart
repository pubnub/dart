import 'package:test/test.dart';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/logging/logging.dart';

void main() {
  group('Logging', () {
    group('[StreamLogger]', () {
      late StreamLogger logger;
      late StreamLogger testLogger;

      setUp(() {
        logger = StreamLogger.root('root');
        testLogger = logger.get('test.logger2');
      });

      test('root logger should emit all in any order', () async {
        var result = expectLater(
          logger.stream.map((record) => record.message),
          emitsInAnyOrder(
              ['test1', 'test1.1', 'test1.2', 'test2', 'test2.1', 'test2.2']),
        );

        await provideLogger(logger, () async {
          var logger = injectLogger('test');
          var logger1 = injectLogger('test.logger1');
          var logger2 = injectLogger('test.logger2');

          logger.info('test1');
          logger1.info('test1.1');
          logger2.info('test1.2');

          logger.info('test2');
          logger1.info('test2.1');
          logger2.info('test2.2');
        });

        await result;
      });

      test('leaf logger should emit in order', () async {
        var result = expectLater(
          testLogger.stream.map((record) => record.message),
          emitsInOrder(['test1.2', 'test2.2']),
        );

        await provideLogger(logger, () async {
          var logger = injectLogger('test');
          var logger1 = injectLogger('test.logger1');
          var logger2 = injectLogger('test.logger2');

          logger.info('test1');
          logger1.info('test1.1');
          logger2.info('test1.2');

          logger.info('test2');
          logger1.info('test2.1');
          logger2.info('test2.2');
        });

        await result;
      });
    });
  });
}
