import 'package:encrypt/encrypt.dart' as crypto;
import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert' show base64, utf8;
import 'dart:typed_data' show Uint8List;

import 'package:pubnub/core.dart';
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

/// Default cryptography module used in PubNub SDK.
class CryptoModule implements ICryptoModule {
  final CryptoConfiguration defaultConfiguration;

  /// Default configuration is:
  /// * `encryptionMode` set to [EncryptionMode.CBC].
  /// * `encryptKey` set to `true`.
  /// * `useRandomInitializationVector` set to `true`.
  CryptoModule({this.defaultConfiguration = const CryptoConfiguration()});

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
  dynamic decrypt(CipherKey key, String input,
      {CryptoConfiguration? configuration}) {
    var config = configuration ?? defaultConfiguration;

    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));
    try {
      if (config.useRandomInitializationVector) {
        var data = base64.decode(input);
        return utf8.decode(encrypter.decryptBytes(
            crypto.Encrypted(Uint8List.fromList(data.sublist(16))),
            iv: crypto.IV.fromBase64(base64.encode(data.sublist(0, 16)))));
      } else {
        var iv = crypto.IV.fromUtf8('0123456789012345');
        return encrypter.decrypt64(input, iv: iv);
      }
    } catch (e) {
      throw CryptoException('Error while decrypting message:\n$e');
    }
  }

  /// Encrypts [input] with [key] based on [configuration].
  ///
  /// If [configuration] is `null`, then [CryptoModule.defaultConfiguration] is used.
  @override
  String encrypt(CipherKey key, dynamic input,
      {CryptoConfiguration? configuration}) {
    var config = configuration ?? defaultConfiguration;

    var encrypter = crypto.Encrypter(
        crypto.AES(_getKey(key, config), mode: config.encryptionMode.value()));
    try {
      if (config.useRandomInitializationVector) {
        var iv = crypto.IV.fromSecureRandom(16);

        var encrypted = encrypter.encrypt(input, iv: iv).bytes;
        return base64.encode([...iv.bytes, ...encrypted]);
      } else {
        var iv = crypto.IV.fromUtf8('0123456789012345');
        return encrypter.encrypt(input, iv: iv).base64;
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

  /// @nodoc
  @override
  void register(Core core) {}
}
