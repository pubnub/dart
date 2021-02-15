import 'package:encrypt/encrypt.dart' show AESMode;

/// Encryption mode of AES used in crypto.
enum EncryptionMode { CBC, ECB }

/// @nodoc
extension EncryptionModeExtension on EncryptionMode {
  AESMode value() {
    switch (this) {
      case EncryptionMode.CBC:
        return AESMode.cbc;
      case EncryptionMode.ECB:
        return AESMode.ecb;
      default:
        throw Exception('Unreachable state');
    }
  }
}
