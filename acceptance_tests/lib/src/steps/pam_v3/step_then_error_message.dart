import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorMessage extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error message is {string}');

  @override
  Future<void> executeStep(String message) async {
    this.expect(world.scenarioContext['errorDetails'], contains(message));
  }
}
