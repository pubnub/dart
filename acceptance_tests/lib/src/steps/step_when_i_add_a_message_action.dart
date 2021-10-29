import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepWhenIAddAMessageAction extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I add a message action');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'addMessageAction';
      world.latestResult = await world.pubnub.addMessageAction(
        type: 'type',
        value: 'value',
        channel: 'channel',
        timetoken: Timetoken(BigInt.parse('1234567890123')),
      );
    } catch (e) {
      world.latestResultType = 'addMessageActionFailure';
      world.latestResult = e;
    }
  }
}
