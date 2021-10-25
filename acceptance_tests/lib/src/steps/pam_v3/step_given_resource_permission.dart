import 'package:gherkin/gherkin.dart';

import '../../world.dart';
import '_context_model.dart';

class StepGivenResourcePermission
    extends Given2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'(grant|deny) resource permission (READ|WRITE|MANAGE|DELETE|CREATE|GET|UPDATE|JOIN)');

  @override
  Future<void> executeStep(String apply, String permission) async {
    var isAllowed = (apply == 'grant') ? true : false;
    (world.scenarioContext['resources'] as List<ResourceDetails>)
        .firstWhere((resource) =>
            resource.name == world.scenarioContext['currentResourceName'] &&
            resource.resourceType ==
                world.scenarioContext['currentResourceType'])
        .permissions[permission] = isAllowed;
  }
}
