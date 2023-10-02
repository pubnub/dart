import 'encryption_mode.dart';

/// Configuration used in cryptography.
class CryptoConfiguration {
  /// Encryption mode used.
  final EncryptionMode encryptionMode;

  /// Whether key should be encrypted.
  final bool encryptKey;

  /// Whether a random IV should be used.
  final bool useRandomInitializationVector;

  const CryptoConfiguration(
      {this.encryptionMode = EncryptionMode.CBC,
      this.encryptKey = true,
      this.useRandomInitializationVector = true});
}
