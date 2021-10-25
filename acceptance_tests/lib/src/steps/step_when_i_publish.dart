import 'package:gherkin/gherkin.dart';

import '../world.dart';

class StepWhenIPublish extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I publish a message');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'publish';

      world.latestResult =
          await world.pubnub.publish('test', 'hello', keyset: world.keyset);
    } catch (e) {
      world.latestResultType = 'publishFailure';
      world.latestResult = e;
    }
  }
}
