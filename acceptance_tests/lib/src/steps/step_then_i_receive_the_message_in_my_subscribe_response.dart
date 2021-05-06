import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepThenIReceiveTheMessageInMySubscribeResponse
    extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I receive the {string} message in my subscribe response');

  @override
  Future<void> executeStep(String message) async {
    this.expect(world.currentSubscription, isNotNull);

    var envelope = await world.currentSubscription.messages.first;

    this.expect(envelope.payload, equals(message));

    await world.currentSubscription.dispose();
  }
}
