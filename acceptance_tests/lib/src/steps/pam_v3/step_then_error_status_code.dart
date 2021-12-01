import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenErrorStatusCode extends Then1WithWorld<int, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the error status code is {int}');

  @override
  Future<void> executeStep(int statusCode) async {
    if (statusCode == 403) {
      this.expect(
          world.scenarioContext['exception'], isA<ForbiddenException>());
    } else {
      this.expect(
          world.scenarioContext['errorDetails'], contains('$statusCode'));
    }
  }
}
