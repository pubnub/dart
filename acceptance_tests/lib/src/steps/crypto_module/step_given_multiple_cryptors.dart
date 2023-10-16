import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenCryptoModuleWithMultipleCryptors
    extends Given2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'Crypto module with default {string} and additional {string} cryptors');

  @override
  Future<void> executeStep(
      String defaultCryptorId, String additionalCryptorId) async {
    world.scenarioContext['defaultCryptorId'] = defaultCryptorId;
    world.scenarioContext['additionalCryptorId'] = additionalCryptorId;
  }
}
