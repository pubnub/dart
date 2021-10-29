import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepWhenIRequestCurrentTime extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I request current time');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'time';
      world.latestResult = await world.pubnub.time();
    } catch (e) {
      world.latestResultType = 'timeFailure';
      world.latestResult = e;
    }
  }
}
