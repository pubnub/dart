import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';
import '_context_model.dart';

class StepWhenGrantToken extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I grant a token specifying those permissions');

  @override
  Future<void> executeStep() async {
    var tokenRequest = world.scenarioContext['tokenRequest'] as TokenRequest;
    if (world.scenarioContext['resources'] != null) {
      for (ResourceDetails resource in world.scenarioContext['resources']) {
        tokenRequest.add(
          resource.resourceType,
          name: resource.name,
          read: resource.permissions['READ'],
          write: resource.permissions['WRITE'],
          manage: resource.permissions['MANAGE'],
          delete: resource.permissions['DELETE'],
          create: resource.permissions['CREATE'],
          get: resource.permissions['GET'],
          update: resource.permissions['UPDATE'],
          join: resource.permissions['JOIN'],
        );
      }
    }
    if (world.scenarioContext['resourcesPattern'] != null) {
      for (ResourceDetails resource
          in world.scenarioContext['resourcesPattern']) {
        tokenRequest.add(
          resource.resourceType,
          pattern: resource.pattern,
          read: resource.permissions['READ'],
          write: resource.permissions['WRITE'],
          manage: resource.permissions['MANAGE'],
          delete: resource.permissions['DELETE'],
          create: resource.permissions['CREATE'],
          get: resource.permissions['GET'],
          update: resource.permissions['UPDATE'],
          join: resource.permissions['JOIN'],
        );
      }
    }

    try {
      world.latestResult = await world.pubnub.grantToken(tokenRequest);
      world.scenarioContext['grantTokenString'] = '${world.latestResult}';
    } catch (e) {
      print(e);
    }
  }
}
