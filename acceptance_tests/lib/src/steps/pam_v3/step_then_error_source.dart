import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorSource extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error source is {string}');

  @override
  Future<void> executeStep(String source) async {
    this.expect(
        world.scenarioContext['errorDetails'], contains('of $source api'));
  }
}
