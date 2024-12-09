import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepWhenISubscribeChannalForCustomMessageType
    extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I subscribe to {string} channel');

  @override
  Future<void> executeStep(String channel) async {
    try {
      var subscription = world.pubnub.subscribe(channels: {channel});
      subscription.messages.listen((messageEnvelope) {
        world.messages.add(messageEnvelope);
      });
      await Future.delayed(Duration(seconds: 2), () {
        subscription.dispose();
      });
      world.latestResultType = 'subscription';
    } catch (e) {
      world.latestResultType = 'subscriptionFailure';
      world.latestResult = e;
    }
  }
}
