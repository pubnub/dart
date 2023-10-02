import '../core.dart';
import '../exceptions.dart';
import 'cipher_key.dart';

export 'cipher_key.dart';

/// Exception thrown when encryption or decryption fails.
///
/// {@category Exceptions}
class CryptoException extends PubNubException {
  CryptoException(String message) : super(message);
}

/// @nodoc
abstract class ILegacyCryptor {
  void register(Core core);

  String encrypt(CipherKey key, String input);
  dynamic decrypt(CipherKey key, String input);

  List<int> encryptFileData(CipherKey key, List<int> input);
  List<int> decryptFileData(CipherKey key, List<int> input);
}

abstract class ICryptoModule {
  void register(Core core);

  List<int> encrypt(List<int> input);
  List<int> decrypt(List<int> input);

  List<int> encryptFileData(CipherKey key, List<int> input);
  List<int> decryptFileData(CipherKey key, List<int> input);

  List<int> encryptWithKey(CipherKey key, List<int> input);
  List<int> decryptWithKey(CipherKey key, List<int> input);
}

/// @nodoc
abstract class ICryptor {
  String get identifier;

  EncryptedData encrypt(List<int> input);
  List<int> decrypt(EncryptedData input);

  EncryptedData encryptFileData(List<int> input);
  List<int> decryptFileData(EncryptedData input);
}

class EncryptedData {
  List<int> _data;
  List<int>? _metadata;

  List<int> get data => _data;
  List<int>? get metadata => _metadata;

  EncryptedData._(this._data, this._metadata);

  factory EncryptedData.from(data, metadata) => EncryptedData._(data, metadata);
}
