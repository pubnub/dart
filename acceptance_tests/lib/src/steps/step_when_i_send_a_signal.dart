import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepWhenISendASignal extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I send a signal');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'signal';
      world.latestResult =
          await world.pubnub.signal('demo', 'my message', keyset: world.keyset);
    } catch (e) {
      world.latestResultType = 'signalFailure';
      world.latestResult = e;
    }
  }
}
