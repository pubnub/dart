import 'dart:convert';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/crypto/aesCbcCryptor.dart';
import 'package:pubnub/src/crypto/crypto.dart';

import 'package:test/test.dart';

void main() {
  late CryptoModule crypto;
  late CipherKey key;

  group('Crypto [PubNubCryptoModule]', () {
    setUp(() {
      key = CipherKey.fromUtf8('thecustomsecretkey');
      crypto = CryptoModule();
    });

    test('should work in two ways', () async {
      var plaintext = 'hello world';

      var ciphertext = crypto.encrypt(key, plaintext);

      var result = crypto.decrypt(key, ciphertext);

      expect(result, equals(plaintext));
    });

    test('cryptoHeader tryParse/data from encrypted text', () async {
      var encryptedDataWithHeader = 'PNEDACRH�_�ƿ';
      var headerData = [80, 78, 69, 68, 1, 65, 67, 82, 72, 16];
      var expectedBytes = [...headerData, ...List<int>.filled(16, 0)];

      var header = CryptorHeader.tryParse(encryptedDataWithHeader.codeUnits);
      expect(header!.data, equals(expectedBytes));
    });

    test('AesCbcCryptor should work as expected', () async {
      var plainText = 'Hello there!';
      var cryptor = AesCbcCryptor(CipherKey.fromUtf8('pubnubenigma'));
      var encryptedData = cryptor.encrypt(plainText.codeUnits);
      var decrypted = cryptor.decrypt(encryptedData);
      expect(utf8.decode(decrypted), equals(plainText));
    });
  });
}
