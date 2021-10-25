import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepGivenDemoKeyset extends Given1WithWorld<Keyset, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the {keyset} keyset');

  @override
  Future<void> executeStep(Keyset keyset) async {
    world.keyset = keyset;
  }
}
