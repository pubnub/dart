import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:test/expect.dart';

import '../../world.dart';

class StepThenOutcome extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I receive {string}');

  @override
  Future<void> executeStep(String expected) async {
    if (expected == 'success') {
      this.expect(world.latestException, isNull);
    } else {
      var outcome = world.latestException;
      this.expect(expected, contains((outcome as CryptoException).message));
    }
  }
}
