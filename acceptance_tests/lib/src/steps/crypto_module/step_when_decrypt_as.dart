import 'dart:io';

import 'package:gherkin/gherkin.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/crypto.dart';

import '../../world.dart';
import '_utils.dart';

class StepWhenDecryptFileAs
    extends When2WithWorld<String, String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I decrypt {string} file as {string}');

  @override
  Future<void> executeStep(String file, String format) async {
    var cryptorId = world.scenarioContext['cryptorId'];
    var cipherKey = CipherKey.fromUtf8(world.scenarioContext['cipherKey']);
    late ICryptor cryptor;
    late ICryptoModule cryptoModule;
    if (cryptorId == 'legacy') {
      cryptor = LegacyCryptor(cipherKey,
          cryptoConfiguration: CryptoConfiguration(
              useRandomInitializationVector:
                  world.scenarioContext['useRandomIntializationVector']));
      cryptoModule = CryptoModule(defaultCryptor: cryptor);
    } else if (cryptorId == 'acrh') {
      cryptor = AesCbcCryptor(cipherKey);
      cryptoModule = CryptoModule(defaultCryptor: cryptor);
    }
    var defaultCryptorId = world.scenarioContext['defaultCryptorId'];
    if (defaultCryptorId == 'legacy') {
      var defaultCryptor = cryptor = LegacyCryptor(cipherKey,
          cryptoConfiguration: CryptoConfiguration(
              useRandomInitializationVector:
                  world.scenarioContext['useRandomIntializationVector']));
      var additionalCryptor = AesCbcCryptor(cipherKey);
      cryptoModule = CryptoModule(
          defaultCryptor: defaultCryptor, cryptors: [additionalCryptor]);
    } else if (defaultCryptorId == 'acrh') {
      var additionalCryptor = cryptor = LegacyCryptor(cipherKey,
          cryptoConfiguration: CryptoConfiguration(
              useRandomInitializationVector:
                  world.scenarioContext['useRandomIntializationVector']));
      var defaultCryptor = AesCbcCryptor(cipherKey);
      cryptoModule = CryptoModule(
          defaultCryptor: defaultCryptor, cryptors: [additionalCryptor]);
    }
    var fileData = File(getCryptoFilePath(file)).readAsBytesSync().toList();
    world.scenarioContext['decryptedContent'] = cryptoModule.decrypt(fileData);
  }
}
