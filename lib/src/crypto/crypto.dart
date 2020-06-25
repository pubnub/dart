import 'package:encrypt/encrypt.dart' as crypto;
import 'package:crypto/crypto.dart' show sha256;

import '../core/core.dart';
import 'encryption_mode.dart';

class CryptoConfiguration {
  final EncryptionMode encryptionMode;
  final bool encryptKey;

  const CryptoConfiguration({
    this.encryptionMode = EncryptionMode.CBC,
    this.encryptKey = true,
  });
}

class PubNubCryptoModule implements CryptoModule {
  final CryptoConfiguration defaultConfiguration;

  PubNubCryptoModule({this.defaultConfiguration = const CryptoConfiguration()});

  crypto.Key _getKey(CipherKey cipherKey, CryptoConfiguration configuration) {
    if (configuration.encryptKey) {
      return crypto.Key.fromUtf8(
          sha256.convert(cipherKey.data).toString().substring(0, 32));
    } else {
      return crypto.Key(cipherKey.data);
    }
  }

  @override
  String decrypt(CipherKey key, String input,
      {CryptoConfiguration configuration}) {
    var config = configuration ?? defaultConfiguration;

    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));

    var iv = crypto.IV.fromUtf8('0123456789012345');

    try {
      return encrypter.decrypt64(input, iv: iv);
    } catch (e) {
      throw CryptoException('Error while decrypting message \n${e.message}');
    }
  }

  @override
  String encrypt(CipherKey key, String input,
      {CryptoConfiguration configuration}) {
    var config = configuration ?? defaultConfiguration;

    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));

    var iv = crypto.IV.fromUtf8('0123456789012345');

    try {
      return encrypter.encrypt(input, iv: iv).base64;
    } catch (e) {
      throw CryptoException('Error while encrypting message \n${e.message}');
    }
  }
}
