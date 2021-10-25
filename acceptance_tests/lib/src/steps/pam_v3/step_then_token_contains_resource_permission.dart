import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '_utils.dart';
import '../../world.dart';

class StepThenTokenHasResourcePermission
    extends Then2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'the token has {string} (CHANNEL|CHANNEL_GROUP|UUID) resource access permissions');

  @override
  Future<void> executeStep(String resourceName, String resourceType) async {
    if (world.scenarioContext['parsedToken'] == null) {
      world.scenarioContext['parsedToken'] =
          world.pubnub.parseToken(world.scenarioContext['grantTokenString']);
    }
    world.scenarioContext['resourcePermissionBitValue'] =
        (world.scenarioContext['parsedToken'] as Token)
            .resources
            .firstWhere((res) =>
                res.type == getResourceType(resourceType) &&
                res.name == resourceName)
            .bit;
  }
}
