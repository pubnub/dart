import 'package:gherkin/gherkin.dart';

import '../../world.dart';
import '../fixtures/pam.dart';

class StepGivenKnownTokenWithUUIDResourcePatternPermissions
    extends GivenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I have a known token containing UUID pattern Permissions');

  @override
  Future<void> executeStep() async {
    world.scenarioContext['grantTokenString'] = tokenWithUUIDPatternPermissions;
  }
}
