import 'dart:convert' show utf8;

import 'package:pubnub/core.dart';
import 'package:pubnub/crypto.dart';

class LegacyCryptor implements ICryptor {
  final CryptoConfiguration cryptoConfiguration;
  final CipherKey cipherKey;

  late CryptoModule cryptor;

  LegacyCryptor(this.cipherKey,
      {this.cryptoConfiguration = const CryptoConfiguration()}) {
    cryptor = CryptoModule(defaultConfiguration: cryptoConfiguration);
  }

  @override
  List<int> decrypt(EncryptedData input) {
    return utf8.encode(cryptor.decrypt(cipherKey, utf8.decode(input.data)));
  }

  @override
  EncryptedData encrypt(List<int> input) {
    return EncryptedData.from(
        utf8.encode(cryptor.encrypt(cipherKey, utf8.decode(input))), null);
  }

  @override
  String get identifier => '';
}
