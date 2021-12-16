import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorService extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error service is {string}');

  @override
  Future<void> executeStep(String service) async {
    this.expect(world.scenarioContext['errorDetails'], contains(service));
  }
}
