import '../exceptions.dart';
import 'cipher_key.dart';

export 'cipher_key.dart';

class CryptoException extends PubNubException {
  CryptoException([String message]) : super(message);
}

abstract class CryptoModule {
  String encrypt(CipherKey key, String input);
  dynamic decrypt(CipherKey key, String input);

  List<int> encryptFileData(CipherKey key, List<int> input);
  List<int> decryptFileData(CipherKey key, List<int> input);
}
