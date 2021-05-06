import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepWhenISubscribe extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I subscribe');

  @override
  Future<void> executeStep() async {
    this.expect(world.currentChannel, isNotNull);

    world.currentSubscription =
        world.pubnub.subscribe(channels: {world.currentChannel.name});

    await world.currentSubscription.whenStarts;
  }
}
