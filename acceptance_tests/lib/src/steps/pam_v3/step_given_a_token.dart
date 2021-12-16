import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenAToken extends GivenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'a token');

  @override
  Future<void> executeStep() async {
    world.scenarioContext['grantToken'] = 'tokenString';
  }
}
