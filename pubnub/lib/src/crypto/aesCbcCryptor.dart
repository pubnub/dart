import 'package:encrypt/encrypt.dart' as crypto;
import 'package:crypto/crypto.dart' show sha256;
import 'dart:typed_data' show Uint8List;

import 'package:pubnub/core.dart';

final _logger = injectLogger('pubnub.crypto.aescbc');

/// Opaque message thrown for all decryption failures.
///
/// The underlying exception is intentionally excluded from the thrown message
/// to avoid leaking details that could aid a decryption/padding oracle attack.
/// The real cause is logged internally via [_logger] instead.
const String _decryptionErrorMessage = 'decryption error';

/// AesCbcCryptor is new and enhanced cryptor to encrypt/decrypt
/// PubNub messages.
/// It's always preferred to use this cryptor instead old cryptor.
class AesCbcCryptor implements ICryptor {
  CipherKey cipherKey;

  AesCbcCryptor(this.cipherKey);
  @override
  List<int> decrypt(EncryptedData encryptedData) {
    if (encryptedData.data.isEmpty) {
      throw CryptoException('decryption error: empty content');
    }
    var encrypter = crypto.Encrypter(
      crypto.AES(_getKey(), mode: crypto.AESMode.cbc),
    );
    try {
      return encrypter.decryptBytes(
          crypto.Encrypted(Uint8List.fromList(encryptedData.data.toList())),
          iv: crypto.IV(Uint8List.fromList(encryptedData.metadata.toList())));
    } catch (e) {
      _logger.warning('AES-CBC decryption failed: $e');
      throw CryptoException(_decryptionErrorMessage);
    }
  }

  @override
  EncryptedData encrypt(List<int> input) {
    var encrypter = crypto.Encrypter(
      crypto.AES(_getKey(), mode: crypto.AESMode.cbc),
    );
    var iv = _getIv();
    var data = encrypter.encryptBytes(input, iv: iv).bytes.toList();
    return EncryptedData.from(data, iv.bytes.toList());
  }

  @override
  String get identifier => 'ACRH';

  crypto.IV _getIv() {
    return crypto.IV.fromSecureRandom(16);
  }

  crypto.Key _getKey() {
    return crypto.Key.fromBase16(
      sha256.convert(cipherKey.data).toString(),
    );
  }

  @override
  List<int> decryptFileData(EncryptedData input) {
    return decrypt(input);
  }

  @override
  EncryptedData encryptFileData(List<int> input) {
    return encrypt(input);
  }

  @override
  String toString() {
    return 'AesCbcCryptor';
  }
}
