import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepGivenCryptoModule extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'Crypto module with {string} cryptor');

  @override
  Future<void> executeStep(String id) async {
    world.scenarioContext['cryptorId'] = id;
  }
}
