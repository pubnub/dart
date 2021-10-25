import 'package:gherkin/gherkin.dart';

import '../../world.dart';
import '_context_model.dart';

class StepGivenResourcePatternPermission
    extends Given2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'(grant|deny) pattern permission (READ|WRITE|MANAGE|DELETE|CREATE|GET|UPDATE|JOIN)');

  @override
  Future<void> executeStep(String apply, String permission) async {
    var isAllowed = (apply == 'grant') ? true : false;

    (world.scenarioContext['resourcesPattern'] as List<ResourceDetails>)
        .firstWhere((resourceDetail) =>
            resourceDetail.pattern ==
                world.scenarioContext['currentResourcePattern'] &&
            resourceDetail.resourceType ==
                world.scenarioContext['currentResourcePatternType'])
        .permissions[permission] = isAllowed;
  }
}
