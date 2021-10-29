import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorDetailMessage extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error detail message is {string}');

  @override
  Future<void> executeStep(String location) async {
    this.expect(world.scenarioContext['errorDetails'], contains(location));
  }
}
