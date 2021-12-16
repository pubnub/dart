import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepWhenIRevokeAToken extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I revoke a token');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResult = await world.pubnub
          .revokeToken(world.scenarioContext['grantToken'] as String);
    } on PubNubException catch (e) {
      world.scenarioContext['errorDetails'] = e.message;
    }
  }
}
