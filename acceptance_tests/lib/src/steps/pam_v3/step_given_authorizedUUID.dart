import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepGivenAuthUUID extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the authorized UUID {string}');

  @override
  Future<void> executeStep(String uuid) async {
    world.scenarioContext['authorizedUUID'] = uuid;
    (world.scenarioContext['tokenRequest'] as TokenRequest).authorizedUUID =
        uuid;
  }
}
