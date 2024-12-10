import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepWhenIPublishWithCustomType extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I publish message with {string} customMessageType');

  @override
  Future<void> executeStep(String customMesageType) async {
    try {
      world.latestResult = await world.pubnub.publish(
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
