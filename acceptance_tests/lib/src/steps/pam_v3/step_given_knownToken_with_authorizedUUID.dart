import 'package:gherkin/gherkin.dart';

import '../../world.dart';
import '../fixtures/pam.dart';

class StepGivenKnownTokenWithAuthorizedUUID
    extends GivenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I have a known token containing an authorized UUID');

  @override
  Future<void> executeStep() async {
    world.scenarioContext['grantTokenString'] = tokenWithKnownAuthorizedUUID;
  }
}
