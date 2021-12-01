import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/expect.dart';

import '../../world.dart';

class StepWhenIPublishMessageWithAuthToken
    extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'I publish a message using that auth token with channel {string}');

  @override
  Future<void> executeStep(String channel) async {
    this.expect(world.scenarioContext['grantToken'], isNotEmpty,
        reason: 'Token can not be empty');
    try {
      world.latestResult =
          await world.pubnub.publish(channel, 'hello', keyset: world.keyset);
      print('message published');
    } on PubNubException catch (e) {
      world.scenarioContext['errorDetails'] = e.message;
    }
  }
}
