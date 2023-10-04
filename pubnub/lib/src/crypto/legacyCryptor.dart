import 'package:pubnub/core.dart';

import 'package:encrypt/encrypt.dart' as crypto;
import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert' show base64;
import 'dart:typed_data' show Uint8List;

import 'cryptoConfiguration.dart';
import 'encryption_mode.dart';
import 'crypto.dart';

/// Legacy cryptor exists so that SDK will be able to decrypt old contents
/// Which encrypted in past
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
      throw CryptoException('Error while decrypting message:\n$e');
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
      throw CryptoException('Error while encrypting message:\n$e');
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
      throw CryptoException('Error while decrypting file data: \n$e}');
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
      throw CryptoException('Error while encrypting file data:\n$e');
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
}
