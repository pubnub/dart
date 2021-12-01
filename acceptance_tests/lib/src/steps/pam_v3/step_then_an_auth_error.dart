//
import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenAuthErrorIsReturned extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'an auth error is returned');

  @override
  Future<void> executeStep() async {
    this.expect(world.scenarioContext['exception'], isNotNull);
    this.expect(world.scenarioContext['exception'], isA<ForbiddenException>());
  }
}
