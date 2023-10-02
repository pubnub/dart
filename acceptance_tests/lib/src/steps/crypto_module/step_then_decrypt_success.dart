import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:test/test.dart';

import '../../world.dart';
import '_utils.dart';

class ThenDecryptSuccessWithLegacy extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'Successfully decrypt an encrypted file with legacy code');

  @override
  Future<void> executeStep() async {
    ICryptoModule cryptoModule = world.scenarioContext['cryptoModule'];
    var decryptedData =
        cryptoModule.decrypt(world.scenarioContext['encryptedData']);
    this.expect(
        listEquals(decryptedData, world.scenarioContext['fileData']), isTrue);
  }
}
