import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenTokenContainsTTL extends Then1WithWorld<int, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the token contains the TTL {int}');

  @override
  Future<void> executeStep(int ttl) async {
    if (world.scenarioContext['parsedToken'] == null) {
      world.scenarioContext['parsedToken'] =
          world.pubnub.parseToken(world.scenarioContext['grantTokenString']);
    }
    this.expect(
        (world.scenarioContext['parsedToken'] as Token).ttl, equals(ttl));
  }
}
