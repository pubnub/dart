import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenVector extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'with {string} vector');

  @override
  Future<void> executeStep(String vector) async {
    world.scenarioContext['useRandomIntializationVector'] =
        vector == 'constant' ? false : true;
  }
}
