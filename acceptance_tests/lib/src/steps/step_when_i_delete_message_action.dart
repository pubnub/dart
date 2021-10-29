import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepWhenIDeleteAMessageAction extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I delete a message action');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'deleteMessageAction';
      world.latestResult = await world.pubnub.deleteMessageAction(
        'channel',
        messageTimetoken: Timetoken(BigInt.parse('1234567890123')),
        actionTimetoken: Timetoken(BigInt.parse('1234567890123')),
      );
    } catch (e) {
      world.latestResultType = 'deleteMessageActionFailure';
      world.latestResult = e;
    }
  }
}
