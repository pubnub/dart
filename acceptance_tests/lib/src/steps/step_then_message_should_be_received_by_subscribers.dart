import 'package:gherkin/gherkin.dart';

import '../world.dart';

class StepThenMessageShouldBeReceivedBySubscribers
    extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'the message should be received by subscribers');

  @override
  Future<void> executeStep() async {
    //TODO: implement the mock server check
  }
}
