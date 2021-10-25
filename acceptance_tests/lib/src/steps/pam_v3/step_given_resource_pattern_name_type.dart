import 'package:gherkin/gherkin.dart';

import '_context_model.dart';
import '_utils.dart';
import '../../world.dart';

class StepGivenResourcePatternNameAndType
    extends Given2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'the {string} (CHANNEL|CHANNEL_GROUP|UUID) pattern access permissions');

  @override
  Future<void> executeStep(String resourcePattern, String resourceType) async {
    if (world.scenarioContext['resourcesPattern'] == null) {
      world.scenarioContext['resourcesPattern'] = <ResourceDetails>[];
    }
    world.scenarioContext['resourcesPattern'].add(ResourceDetails(
        getResourceType(resourceType),
        pattern: resourcePattern));
    world.scenarioContext['currentResourcePattern'] = resourcePattern;
    world.scenarioContext['currentResourcePatternType'] =
        getResourceType(resourceType);
  }
}
