import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/expect.dart';

import '../../world.dart';

class StepThenIGetConfirmationRevokeToken extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I get confirmation that token has been revoked');

  @override
  Future<void> executeStep() async {
    var result = world.latestResult as PamRevokeTokenResult;
    this.expect(result, isNotNull);
  }
}
