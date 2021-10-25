import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorDetailLocation extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error detail location is {string}');

  @override
  Future<void> executeStep(String location) async {
    this.expect(world.scenarioContext['errorDetails'], contains(location));
  }
}
