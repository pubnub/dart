import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepThenIReceiveTheMessageInMySubscribeResponse
    extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I receive the message in my subscribe response');

  @override
  Future<void> executeStep() async {
    this.expect(world.currentSubscription, isNotNull,
        reason: 'expected `world.currentSubscription` to not be null');

    Envelope? envelope;

    try {
      envelope = await world.firstMessage;
    } catch (e) {
      this.expect(e, isNot(isA<Exception>()),
          reason: 'expected not an exception');
    }

    this.expect(envelope, isNotNull,
        reason: 'expected `envelope` to not be null');

    await world.currentSubscription!.cancel();
  }
}
