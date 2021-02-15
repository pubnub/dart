import 'package:pubnub/logging.dart';
import 'package:pubnub/pubnub.dart';

void main() async {
  const CHANNEL = 'dart-presence-test';
  final SUBSCRIBE_KEY = 'demo';
  final PUBLISH_KEY = 'demo';

  final producerKeyset = Keyset(
      subscribeKey: SUBSCRIBE_KEY,
      publishKey: PUBLISH_KEY,
      uuid: UUID('PRODUCER'));
  final consumerKeyset =
      Keyset(subscribeKey: SUBSCRIBE_KEY, uuid: UUID('CONSUMER'));

  var pubnub = PubNub(defaultKeyset: producerKeyset);
  var logger = StreamLogger.root('test', logLevel: Level.all);

  logger.stream.listen(LogRecord.defaultPrinter);

  await provideLogger(logger, () async {
    var consumerSub = pubnub.subscribe(
        keyset: consumerKeyset, channels: {CHANNEL}, withPresence: true);

    consumerSub.presence.listen((event) {
      print(
          'EVENT: ${event.action} - ${event.uuid} (${event.timetoken}, ${event.occupancy})');
    });

    await pubnub.announceHeartbeat(channels: {CHANNEL}, heartbeat: 10);

    await Future.delayed(Duration(seconds: 10));

    await pubnub.announceLeave(channels: {CHANNEL});
  });
}
