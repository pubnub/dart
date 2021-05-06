import 'package:pubnub/core.dart';
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
  });
}
