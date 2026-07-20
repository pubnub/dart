import 'encryption_mode.dart';

/// Configuration used in cryptography.
class CryptoConfiguration {
  /// Encryption mode used.
  final EncryptionMode encryptionMode;

  /// Whether key should be encrypted.
  final bool encryptKey;

  /// Whether a random IV should be used.
  ///
  /// A random initialization vector is required for secure encryption. Setting
  /// this to `false` selects a hard-coded static IV, which is insecure and
  /// exists only to decrypt historical content. Prefer [AesCbcCryptor], which
  /// always uses a random IV.
  @Deprecated(
      'A static initialization vector is insecure. Keep this enabled (the '
      'default) or migrate to AesCbcCryptor. The static-IV option is retained '
      'only for backward-compatible decryption and will be removed in a future '
      'release.')
  final bool useRandomInitializationVector;

  const CryptoConfiguration(
      {this.encryptionMode = EncryptionMode.CBC,
      this.encryptKey = true,
      // ignore: deprecated_member_use_from_same_package
      this.useRandomInitializationVector = true});
}
