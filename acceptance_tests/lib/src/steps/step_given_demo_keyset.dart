import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepGivenDemoKeyset extends GivenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the demo keyset');

  @override
  Future<void> executeStep() async {
    world.keyset = Keyset(
      subscribeKey: 'demo',
      publishKey: 'demo',
      uuid: UUID('dart-acceptance-testing'),
    );
  }
}
