import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorIsReturned extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'an error is returned');

  @override
  Future<void> executeStep() async {
    this.expect(world.scenarioContext['errorDetails'], isNotNull);
  }
}
