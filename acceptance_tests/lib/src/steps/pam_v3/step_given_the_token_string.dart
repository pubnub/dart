import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenTheTokenString extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the token string {string}');

  @override
  Future<void> executeStep(String tokenString) async {
    world.scenarioContext['grantToken'] = tokenString;
  }
}
