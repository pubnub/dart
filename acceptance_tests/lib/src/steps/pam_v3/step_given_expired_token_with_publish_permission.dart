import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenExpiredTokenWithPublishPermission
    extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'an expired token with permissions to publish with channel {string}');

  @override
  Future<void> executeStep(String channel) async {
    world.scenarioContext['grantToken'] = 'expiredToken';
    world.pubnub.setToken('expiredToken', keyset: world.keyset);
  }
}
