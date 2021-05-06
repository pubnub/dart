import 'package:gherkin/gherkin.dart';

import '../world.dart';

class StepGivenChannel extends Given1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the channel {string}');

  @override
  Future<void> executeStep(String channel) async {
    world.currentChannel = world.pubnub.channel(channel);
  }
}
