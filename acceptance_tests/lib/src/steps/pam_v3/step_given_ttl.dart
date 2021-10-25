import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepGivenTtl extends Given1WithWorld<int, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the TTL {int}');

  @override
  Future<void> executeStep(int ttl) async {
    world.scenarioContext['ttl'] = ttl;
    (world.scenarioContext['tokenRequest'] as TokenRequest).ttl = ttl;
  }
}
