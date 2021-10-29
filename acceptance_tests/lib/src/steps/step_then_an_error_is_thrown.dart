import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepThenAnErrorIsThrown extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'an error is thrown');

  @override
  Future<void> executeStep() async {
    this.expect(world.currentSubscription, isNotNull,
        reason: 'expected `world.currentSubscription` to not be null');

    Envelope? result;

    try {
      result = await world.firstMessage;
    } catch (exception) {
      this.expect(exception, isA<Exception>());
    }

    this.expect(result, isNull, reason: 'expected an exception to happen');

    await world.currentSubscription!.cancel();
  }
}
