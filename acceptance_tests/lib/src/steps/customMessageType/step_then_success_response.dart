import 'package:gherkin/gherkin.dart';
import 'package:test/expect.dart';

import '../../world.dart';

class StepThenIReceiveSuccessfulResponsePublish extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I receive a successful response');

  @override
  Future<void> executeStep() async {
    this.expect(world.latestResultType, isNotNull);
  }
}