import 'package:encrypt/encrypt.dart' show AESMode;

enum EncryptionMode { CBC, ECB }

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
