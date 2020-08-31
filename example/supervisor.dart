import 'dart:io';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/networking.dart';

void main() async {
  var logger = StreamLogger.root('root', logLevel: Level.warning);

  // Subscribe to messages with a default printer
  logger.stream.listen(
      LogRecord.createPrinter(r'[$time] (${level.name}) $scope $message'));

  await provideLogger(logger, () async {
    // Create PubNub instance with default keyset.
    var pubnub = PubNub(
      networking: NetworkingModule(
          retryPolicy: RetryPolicy.exponential(maxRetries: 10)),
      defaultKeyset:
          Keyset(subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('demo')),
    );

    print(
        'Network reconnection test. Please wait few seconds for further instructions...');

    var sub = await pubnub.subscribe(channels: {'test2'});

    await Future.delayed(Duration(seconds: 5));

    print('Subscribed. Disconnect your network for few seconds.');

    await Future.delayed(Duration(seconds: 5));

    var f = pubnub.publish('test2', {'myMessage': 'it works!'});

    print(
        'Now reconnect your network again! If everything goes well, you should see the message. You will see few diagnostic log lines in the meantime.');

    await f;

    var message = await sub.messages.first;

    print(message.payload);

    await sub.dispose();

    print('Done!');

    exit(0);
  });
}
