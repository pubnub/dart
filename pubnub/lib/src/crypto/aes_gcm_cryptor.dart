import 'package:crypto/crypto.dart' show sha256;
import 'package:encrypt/encrypt.dart' as crypto;
import 'package:pubnub/core.dart';
import 'dart:typed_data' show Uint8List;

import 'cryptorHeader.dart';

final _logger = injectLogger('pubnub.crypto.aesgcm');

/// Opaque message thrown for all decryption failures.
///
/// The underlying exception is intentionally excluded from the thrown message
/// to avoid leaking details that could aid an authentication oracle. The real
/// cause is logged internally via [_logger] instead.
const String _decryptionErrorMessage = 'decryption error';

/// Thrown because AES-GCM encryption is not available.
const String _encryptionUnavailableMessage =
    'encryption error: AES-GCM encryption is not available';

/// Decrypts AES-256-GCM payloads identified by [cryptorId].
///
/// The cipher key is SHA-256(cipher key). Header metadata is the 12-byte
/// nonce, and the 16-byte authentication tag follows the ciphertext.
///
/// @nodoc
class AesGcmCryptor implements ICryptor {
  static const String cryptorId = 'ACGM';
  static const int nonceSize = 12;
  static const int tagSize = 16;

  final CipherKey cipherKey;

  AesGcmCryptor(this.cipherKey);

  /// Decrypts a full `PNED` payload when its cryptor id is [cryptorId].
  ///
  /// Returns null when [input] is not an AES-256-GCM payload. An empty list
  /// is a successful decryption of an empty plaintext.
  static List<int>? tryDecrypt(CipherKey key, List<int> input) {
    CryptorHeaderV1? header;
    try {
      header = CryptorHeader.tryParse(input);
    } on CryptoException {
      return null;
    }
    if (header == null || header.identifier != cryptorId) {
      return null;
    }
    if (header.length > input.length) {
      throw CryptoException(_decryptionErrorMessage);
    }
    var headerLength = header.length;
    var metadata =
        input.sublist(headerLength - header.metadataLength, headerLength);
    return AesGcmCryptor(key).decrypt(
      EncryptedData.from(input.sublist(headerLength), metadata),
    );
  }

  @override
  String get identifier => cryptorId;

  @override
  EncryptedData encrypt(List<int> input) {
    throw CryptoException(_encryptionUnavailableMessage);
  }

  @override
  EncryptedData encryptFileData(List<int> input) {
    throw CryptoException(_encryptionUnavailableMessage);
  }

  @override
  List<int> decrypt(EncryptedData encryptedData) {
    if (encryptedData.metadata.length != nonceSize ||
        encryptedData.data.length < tagSize) {
      throw CryptoException(_decryptionErrorMessage);
    }

    // Keep the default padding. It selects GCMBlockCipher.process, which
    // checks the authentication tag. Passing padding: null skips that check.
    var encrypter = crypto.Encrypter(
      crypto.AES(_getKey(), mode: crypto.AESMode.gcm),
    );
    try {
      return encrypter.decryptBytes(
        crypto.Encrypted(Uint8List.fromList(encryptedData.data)),
        iv: crypto.IV(Uint8List.fromList(encryptedData.metadata)),
        associatedData: Uint8List(0),
      );
    } catch (e) {
      _logger.warning('AES-GCM decryption failed: $e');
      throw CryptoException(_decryptionErrorMessage);
    }
  }

  @override
  List<int> decryptFileData(EncryptedData input) {
    return decrypt(input);
  }

  crypto.Key _getKey() {
    return crypto.Key.fromBase16(sha256.convert(cipherKey.data).toString());
  }

  @override
  String toString() {
    return 'AesGcmCryptor';
  }
}
