// history response contains messages without customMessageType
import 'package:gherkin/gherkin.dart';
import 'package:test/expect.dart';

import '../../world.dart';

class StepThenReceivedMessagesNoCustomMessageTypes
    extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'history response contains messages without customMessageType');

  @override
  Future<void> executeStep(
      ) async {
    world.messages.forEach((message) {
      expect(
          message.customMessageType,
          null);
    });
  }
}
