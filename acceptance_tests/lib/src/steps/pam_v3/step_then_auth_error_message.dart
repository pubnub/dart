// the auth error message is 'Token is expired.'

import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenAuthErrorMessage extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the auth error message is {string}');

  @override
  Future<void> executeStep(String message) async {
    this.expect(
        (world.scenarioContext['exception'] as ForbiddenException).message,
        contains(message));
  }
}
