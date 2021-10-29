import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenParsedTokenContainsGivenAuthorizedUUID
    extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'the parsed token output contains the authorized UUID {string}');

  @override
  Future<void> executeStep(String authorizedUUID) async {
    this.expect((world.scenarioContext['parsedToken'] as Token).authorizedUUID,
        equals(authorizedUUID));
  }
}
