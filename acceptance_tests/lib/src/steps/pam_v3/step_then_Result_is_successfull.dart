import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenResultIsSuccessfull extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the result is successful');

  @override
  Future<void> executeStep() async {
    this.expect(world.latestResult as PublishResult, isNotNull);
  }
}
