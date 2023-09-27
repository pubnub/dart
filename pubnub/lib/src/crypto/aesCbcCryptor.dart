import 'package:encrypt/encrypt.dart' as crypto;
import 'package:crypto/crypto.dart' show sha256;
import 'dart:typed_data' show Uint8List;

import 'package:pubnub/core.dart';
class AesCbcCryptor implements ICryptor {
  static const BLOCK_SIZE = 16;
  CipherKey cipherKey;

  AesCbcCryptor(this.cipherKey);
  @override
  List<int> decrypt(EncryptedData encryptedData) {
    var encrypter =
        crypto.Encrypter(crypto.AES(_getKey(), mode: crypto.AESMode.cbc));
    return encrypter.decryptBytes(
        crypto.Encrypted(Uint8List.fromList(encryptedData.data.toList())),
        iv: crypto.IV(Uint8List.fromList(encryptedData.metadata.toList())));
  }

  @override
  EncryptedData encrypt(List<int> input) {
    var encrypter =
        crypto.Encrypter(crypto.AES(_getKey(), mode: crypto.AESMode.cbc));
    var iv = _getIv();
    var data = encrypter.encryptBytes(input, iv: iv).bytes.toList();
    return EncryptedData.from(data, iv.bytes.toList());
  }

  @override
  String get identifier => 'ACRH';

  crypto.IV _getIv() {
    return crypto.IV.fromSecureRandom(BLOCK_SIZE);
  }

  crypto.Key _getKey() {
    return crypto.Key.fromBase16(sha256.convert(cipherKey.data).toString());
  }
}
