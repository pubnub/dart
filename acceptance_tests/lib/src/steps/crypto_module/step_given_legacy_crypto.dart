import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenLegacyCryptoModule
    extends Given2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'Legacy code with {string} cipher key and {vector} vector');

  @override
  Future<void> executeStep(String cipherKey, String vector) async {
    world.scenarioContext['useRandomIntializationVector'] =
        vector == 'constant' ? false : true;
    world.scenarioContext['cipherKey'] = cipherKey;
  }
}
