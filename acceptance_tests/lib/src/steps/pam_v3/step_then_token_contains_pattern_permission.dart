import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '_utils.dart';
import '../../world.dart';

class StepThenTokenHasResourcePatternPermission
    extends Then2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'the token has {string} (CHANNEL|CHANNEL_GROUP|UUID) pattern access permissions');

  @override
  Future<void> executeStep(String resourcePattern, String resourceType) async {
    if (world.scenarioContext['parsedToken'] == null) {
      world.scenarioContext['parsedToken'] =
          world.pubnub.parseToken(world.scenarioContext['grantTokenString']);
    }
    world.scenarioContext['resourcePatternPermissionBitValue'] =
        (world.scenarioContext['parsedToken'] as Token)
            .patterns
            .firstWhere((res) =>
                res.type == getResourceType(resourceType) &&
                res.pattern == resourcePattern)
            .bit;
  }
}
