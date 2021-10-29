import 'package:gherkin/gherkin.dart';

import '_context_model.dart';
import '_utils.dart';
import '../../world.dart';

class StepGivenResourceNameAndType
    extends Given2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'the {string} (CHANNEL|CHANNEL_GROUP|UUID) resource access permissions');

  @override
  Future<void> executeStep(String resourceName, String resourceType) async {
    if (world.scenarioContext['resources'] == null) {
      world.scenarioContext['resources'] = <ResourceDetails>[];
    }
    world.scenarioContext['resources'].add(
        ResourceDetails(getResourceType(resourceType), name: resourceName));
    world.scenarioContext['currentResourceName'] = resourceName;
    world.scenarioContext['currentResourceType'] =
        getResourceType(resourceType);
  }
}
