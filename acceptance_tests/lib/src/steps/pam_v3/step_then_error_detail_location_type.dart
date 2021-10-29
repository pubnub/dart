import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorDetailLocationType
    extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error detail location type is {string}');

  @override
  Future<void> executeStep(String locationType) async {
    this.expect(world.scenarioContext['errorDetails'], contains(locationType));
  }
}
