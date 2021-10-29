import 'package:gherkin/gherkin.dart';

import '../../world.dart';
import '../fixtures/pam.dart';

class StepGivenKnownTokenWithUUIDResourcePermissions
    extends GivenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I have a known token containing UUID resource permissions');

  @override
  Future<void> executeStep() async {
    world.scenarioContext['grantTokenString'] =
        tokenWithUUIDResourcePermissions;
  }
}
