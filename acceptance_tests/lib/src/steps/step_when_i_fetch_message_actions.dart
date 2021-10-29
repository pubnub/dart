import 'package:gherkin/gherkin.dart';

import '../world.dart';

class StepWhenIFetchMessageActions extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I fetch message actions');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'fetchMessageAction';
      world.latestResult = await world.pubnub.fetchMessageActions('channel');
    } catch (e) {
      world.latestResultType = 'fetchMessageActionFailure';
      world.latestResult = e;
    }
  }
}
