import 'dart:io';

import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/crypto.dart';

import '../../world.dart';
import '_utils.dart';

class StepWhenDecryptFile extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I decrypt {string} file');

  @override
  Future<void> executeStep(String file) async {
    late ICryptoModule cryptoModule;
    var cipherKey = CipherKey.fromUtf8(world.scenarioContext['cipherKey']);
    if (world.scenarioContext['cryptorId'] == 'acrh') {
      cryptoModule = CryptoModule(defaultCryptor: AesCbcCryptor(cipherKey));
    }
    var data = File(getCryptoFilePath(file)).readAsBytesSync().toList();
    try {
      cryptoModule.decrypt(data);
    } catch (e) {
      world.latestException = e;
    }
  }
}
