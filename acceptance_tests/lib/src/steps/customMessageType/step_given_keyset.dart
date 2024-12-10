import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepGivenTheDemoKeyset extends GivenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the demo keyset');

  @override
  Future<void> executeStep() async {
    world.keyset = Keyset(
      publishKey: 'demo',
      subscribeKey: 'demo',
      userId: UserId('testCustomType')      
    );
  }
}
