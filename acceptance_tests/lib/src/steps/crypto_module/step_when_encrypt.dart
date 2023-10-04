import 'dart:io';

import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/crypto.dart';

import '../../world.dart';
import '_utils.dart';

class StepWhenEncrypt extends When2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I encrypt {string} file as {string}');

  @override
  Future<void> executeStep(String file, String format) async {
    if (format == 'binary') {
      var fileData = File(getCryptoFilePath(file)).readAsBytesSync().toList();
      world.scenarioContext['fileData'] = fileData;

      var cryptor = LegacyCryptor(
          CipherKey.fromUtf8(world.scenarioContext['cipherKey']),
          cryptoConfiguration: CryptoConfiguration(
              useRandomInitializationVector:
                  world.scenarioContext['useRandomIntializationVector']));
      var cryptoModule = CryptoModule(defaultCryptor: cryptor);
      world.scenarioContext['cryptoModule'] = cryptoModule;
      try {
        var encryptedData = cryptoModule.encrypt(fileData);
        world.scenarioContext['encryptedData'] = encryptedData;
      } catch (e) {
        world.latestException = e;
      }
    }
  }
}
