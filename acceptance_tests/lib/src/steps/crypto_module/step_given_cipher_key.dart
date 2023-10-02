import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenCipherKey extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'with {string} cipher key');

  @override
  Future<void> executeStep(String cipherKey) async {
    world.scenarioContext['cipherKey'] = cipherKey;
  }
}
