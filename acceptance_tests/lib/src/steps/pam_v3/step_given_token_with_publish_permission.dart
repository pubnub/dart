import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenATokenWithPublishPermission
    extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'a valid token with permissions to publish with channel {string}');

  @override
  Future<void> executeStep(String channel) async {
    world.scenarioContext['grantToken'] = 'validTokenString';
    world.pubnub.setToken('validTokenString', keyset: world.keyset);
  }
}
