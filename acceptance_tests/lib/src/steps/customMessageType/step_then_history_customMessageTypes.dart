import 'package:gherkin/gherkin.dart';
import 'package:test/expect.dart';

import '../../world.dart';

class StepThenHistoryReceivedMessagesHasCustomMessageTypes
    extends Then2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'history response contains messages with {string} and {string} types');

  @override
  Future<void> executeStep(
      String customMessageTypeOne, String customMessageTypeTwo) async {
    world.historyMessages.forEach((message) {
      this.expect(message.customMessageType,
          anyOf([customMessageTypeOne, customMessageTypeTwo]));
    });
  }
}
