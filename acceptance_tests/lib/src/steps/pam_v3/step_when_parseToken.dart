import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepWhenParseToken extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I parse the token');

  @override
  Future<void> executeStep() async {
    world.scenarioContext['parsedToken'] =
        world.pubnub.parseToken(world.scenarioContext['grantTokenString']);
  }
}
