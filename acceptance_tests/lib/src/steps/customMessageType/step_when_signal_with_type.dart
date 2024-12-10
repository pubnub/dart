import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepWhenISignalWithCustomType
    extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I send a signal with {string} customMessageType');

  @override
  Future<void> executeStep(String customMesageType) async {
    try {
      world.latestResult = await world.pubnub.signal(
        'test',
        'hello',
        keyset: world.keyset,
        customMessageType: customMesageType,
      );
      world.latestResultType = 'publish';
    } catch (e) {
      world.latestResultType = 'publishWithCustomTypeFailure';
      world.latestResult = e;
    }
  }
}
