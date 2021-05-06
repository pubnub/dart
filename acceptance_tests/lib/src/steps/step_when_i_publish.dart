import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepWhenIPublish extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I publish the message {string}');

  @override
  Future<void> executeStep(String message) async {
    this.expect(world.currentChannel, isNotNull);

    world.latestResultType = 'publish';
    world.latestResult = await world.currentChannel.publish(message);
  }
}
