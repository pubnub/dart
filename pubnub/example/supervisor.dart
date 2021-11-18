import 'package:pubnub/pubnub.dart';
import 'package:pubnub/logging.dart';
import 'package:pubnub/networking.dart';

void main() async {
  var logger = StreamLogger.root('root', logLevel: Level.all);

  // Subscribe to messages with a default printer
  logger.stream.listen(
      LogRecord.createPrinter(r'[$time] (${level.name}) $scope $message'));

  // Create PubNub instance with default keyset.
  var pubnub = PubNub(
    networking:
        NetworkingModule(retryPolicy: RetryPolicy.exponential(maxRetries: 10)),
    defaultKeyset:
        Keyset(subscribeKey: 'demo', publishKey: 'demo', uuid: UUID('demo')),
  );

  print(
      '*\n*** Network reconnection test. Please wait few seconds for further instructions. You will see few diagnostic log lines in the meantime.\n*');

  await provideLogger(logger, () async {
    var sub = pubnub.subscribe(channels: {'test2'});

    await Future.delayed(Duration(seconds: 5));

    print('*\n*** Subscribed. Disconnect your network for few seconds.\n*');

    await Future.delayed(Duration(seconds: 5));

    var f = pubnub.publish('test2', {'myMessage': 'it works!'});

    print(
        '*\n*** Now reconnect your network again! If everything goes well, you should see the message.\n*');

    await f;

    var message = await sub.messages.first;

    print('*\n*** ${message.payload}\n*');

    await sub.dispose();

    print('Done!');
  });
}
