import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorDetailMessageIsNotEmpty extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error detail message is not empty');

  @override
  Future<void> executeStep() async {
    this.expect(world.scenarioContext['errorDetails'], isNotEmpty);
  }
}
