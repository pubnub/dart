import 'package:gherkin/gherkin.dart';
import 'package:pubnub/networking.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepGivenPAMenabledKeyset extends GivenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I have a keyset with access manager enabled');

  @override
  Future<void> executeStep() async {
    world.keyset = Keyset(
      subscribeKey: 'demo',
      publishKey: 'demo',
      secretKey: 'demo',
      uuid: UUID('dart-acceptance-testing'),
    );
    world.pubnub = PubNub(
        defaultKeyset: world.keyset,
        networking: NetworkingModule(origin: 'localhost:8090', ssl: false));
    world.scenarioContext['tokenRequest'] = world.pubnub.requestToken(ttl: 15);
  }
}
