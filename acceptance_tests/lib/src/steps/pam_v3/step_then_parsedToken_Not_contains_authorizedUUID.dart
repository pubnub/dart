import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenParsedTokenShouldNotContainAuthorizedUUID
    extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'the token does not contain an authorized uuid');

  @override
  Future<void> executeStep() async {
    if (world.scenarioContext['parsedToken'] == null) {
      world.scenarioContext['parsedToken'] =
          world.pubnub.parseToken(world.scenarioContext['grantTokenString']);
    }
    this.expect(
        (world.scenarioContext['parsedToken'] as Token).authorizedUUID, isNull);
  }
}
