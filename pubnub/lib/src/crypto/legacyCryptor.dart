import 'package:pubnub/core.dart';

import 'package:encrypt/encrypt.dart' as crypto;
import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert' show base64;
import 'dart:typed_data' show Uint8List;

import 'cryptoConfiguration.dart';
import 'encryption_mode.dart';
import 'crypto.dart';

final _logger = injectLogger('pubnub.crypto.legacy');

/// Opaque message thrown for all decryption failures.
///
/// The underlying exception is intentionally excluded from the thrown message
/// to avoid leaking details that could aid a decryption/padding oracle attack.
/// The real cause is logged internally via [_logger] instead.
const String _decryptionErrorMessage = 'decryption error';

/// Opaque message thrown for all encryption failures.
const String _encryptionErrorMessage = 'encryption error';

/// Legacy cryptor exists so that SDK will be able to decrypt old contents
/// which were encrypted in the past.
///
/// It uses AES-CBC with a key derived by SHA-256 and, by default, a random IV.
/// For new applications prefer [AesCbcCryptor], which is the enhanced,
/// recommended cryptor.
@Deprecated(
    'Use AesCbcCryptor for new applications. LegacyCryptor is retained only '
    'to decrypt content encrypted by older SDK versions and will be removed '
    'in a future release.')
class LegacyCryptor implements ICryptor {
  final CryptoConfiguration cryptoConfiguration;
  final CipherKey cipherKey;

  late LegacyCryptoModule cryptor;

  LegacyCryptor(this.cipherKey,
      {this.cryptoConfiguration = const CryptoConfiguration()}) {
    cryptor = LegacyCryptoModule(defaultConfiguration: cryptoConfiguration);
  }

  @override
  List<int> decrypt(EncryptedData input) {
    if (input.data.length <= 16) {
      throw CryptoException('decryption error: empty content');
    }
    return cryptor.decryptWithKey(cipherKey, input.data);
  }

  @override
  EncryptedData encrypt(List<int> input) {
    return EncryptedData.from(
        cryptor.encryptWithKey(cipherKey, input), List<int>.empty());
  }

  @override
  String get identifier => '';

  @override
  List<int> decryptFileData(EncryptedData input) {
    if (input.data.length <= 16) {
      throw CryptoException('decryption error: empty content');
    }
    return cryptor.decryptFileData(cipherKey, input.data);
  }

  @override
  EncryptedData encryptFileData(List<int> input) {
    return EncryptedData.from(
        cryptor.encryptFileData(cipherKey, input), List<int>.empty());
  }

  @override
  String toString() {
    return 'LegacyCryptor';
  }
}

/// Legacy CryptoModule module used in PubNub SDK when CipherKey is not provided.
class LegacyCryptoModule implements ICryptoModule {
  final CryptoConfiguration defaultConfiguration;

  /// Default configuration is:
  /// * `encryptionMode` set to [EncryptionMode.CBC].
  /// * `encryptKey` set to `true`.
  /// * `useRandomInitializationVector` set to `true`.
  LegacyCryptoModule({this.defaultConfiguration = const CryptoConfiguration()});

  crypto.Key _getKey(CipherKey cipherKey, CryptoConfiguration configuration) {
    if (configuration.encryptKey) {
      return crypto.Key.fromUtf8(
          sha256.convert(cipherKey.data).toString().substring(0, 32));
    } else {
      return crypto.Key(Uint8List.fromList(cipherKey.data));
    }
  }

  /// Decrypts [input] with [key] based on [configuration].
  ///
  /// If [configuration] is `null`, then [CryptoModule.defaultConfiguration] is used.
  @override
  List<int> decryptWithKey(CipherKey key, List<int> input,
      {CryptoConfiguration? configuration}) {
    var config = configuration ?? defaultConfiguration;
    if (Uint8List.fromList(input.sublist(16)).isEmpty) {
      throw CryptoException('decryption error: empty content');
    }
    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));
    try {
      // ignore: deprecated_member_use_from_same_package
      if (config.useRandomInitializationVector) {
        return encrypter.decryptBytes(
            crypto.Encrypted(Uint8List.fromList(input.sublist(16))),
            iv: crypto.IV.fromBase64(base64.encode(input.sublist(0, 16))));
      } else {
        var iv = crypto.IV.fromUtf8('0123456789012345');
        return encrypter
            .decryptBytes(crypto.Encrypted(Uint8List.fromList(input)), iv: iv);
      }
    } catch (e) {
      _logger.warning('Legacy message decryption failed: $e');
      throw CryptoException(_decryptionErrorMessage);
    }
  }

  /// Encrypts [input] with [key] based on [configuration].
  ///
  /// If [configuration] is `null`, then [CryptoModule.defaultConfiguration] is used.
  @override
  List<int> encryptWithKey(CipherKey key, List<int> input,
      {CryptoConfiguration? configuration}) {
    var config = configuration ?? defaultConfiguration;

    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));
    try {
      // ignore: deprecated_member_use_from_same_package
      if (config.useRandomInitializationVector) {
        var iv = crypto.IV.fromSecureRandom(16);
        var encrypted = [];
        if (input.isNotEmpty) {
          encrypted = encrypter.encryptBytes(input, iv: iv).bytes;
        }
        return [...iv.bytes, ...encrypted];
      } else {
        var iv = crypto.IV.fromUtf8('0123456789012345');
        if (input.isEmpty) return [...iv.bytes];
        return encrypter.encryptBytes(input, iv: iv).bytes;
      }
    } catch (e) {
      _logger.warning('Legacy message encryption failed: $e');
      throw CryptoException(_encryptionErrorMessage);
    }
  }

  /// Decrypts [input] based on the [key] and [configuration].
  ///
  /// If [configuration] is `null`, then [CryptoModule.defaultConfiguration] is used.
  @override
  List<int> decryptFileData(CipherKey key, List<int> input,
      {CryptoConfiguration? configuration}) {
    var config = configuration ?? defaultConfiguration;
    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));
    try {
      return encrypter.decryptBytes(
          crypto.Encrypted(Uint8List.fromList(input.sublist(16))),
          iv: crypto.IV.fromBase64(base64.encode(input.sublist(0, 16))));
    } catch (e) {
      _logger.warning('Legacy file data decryption failed: $e');
      throw CryptoException(_decryptionErrorMessage);
    }
  }

  /// Encrypts [input] based on the [key] and [configuration].
  ///
  /// If [configuration] is `null`, then [CryptoModule.defaultConfiguration] is used.
  @override
  List<int> encryptFileData(CipherKey key, List<int> input,
      {CryptoConfiguration? configuration}) {
    var iv = crypto.IV.fromSecureRandom(16);
    var config = configuration ?? defaultConfiguration;
    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));

    try {
      var encrypted = encrypter.encryptBytes(input, iv: iv).bytes;
      return [...iv.bytes, ...encrypted];
    } catch (e) {
      _logger.warning('Legacy file data encryption failed: $e');
      throw CryptoException(_encryptionErrorMessage);
    }
  }

  @override
  List<int> decrypt(List<int> input) {
    // Note: Unreachable code. Till the time legacy encryption supported.
    return List.empty();
  }

  @override
  List<int> encrypt(List<int> input) {
    // Note: Unreachable code. Till the time legacy encryption supported.
    return List.empty();
  }

  @override
  void register(Core core) {}

  @override
  String toString() {
    return 'LegacyCryptoModule';
  }
}
