import 'package:encrypt/encrypt.dart' as crypto;
import 'package:crypto/crypto.dart' show sha256;
import 'dart:convert' show base64, utf8;
import 'dart:typed_data' show Uint8List;

import 'package:pubnub/core.dart';
import 'encryption_mode.dart';

class CryptorHeader {
  static const SENTINEL = 'PNED';
  static const LEGACY_IDENTIFIER = '';
  static const IDENTIFIER_LENGTH = 4;
  static const MAX_VERSION = 1;

  static CryptorHeaderV1? from(String id, List<int> metadata) {
    if (id == LEGACY_IDENTIFIER) return null;
    return CryptorHeaderV1(id, metadata.length);
  }

  static CryptorHeaderV1? tryParse(List<int> encryptedData) {
    List<int> sentinel;
    var version;
    if (encryptedData.length >= 4) {
      sentinel = encryptedData.sublist(0, 4).toList();
      if (utf8.decode(sentinel) != SENTINEL) return null;
    }

    if (encryptedData.length >= 5) {
      version = encryptedData[4];
    } else {
      throw PubNubException('decryption error');
    }
    if (version > MAX_VERSION) throw PubNubException('unknown cryptor');

    var identifier;
    var pos = 5 + IDENTIFIER_LENGTH;
    if (encryptedData.length >= pos) {
      identifier = encryptedData.sublist(5, pos).toList();
    } else {
      throw PubNubException('decryption error');
    }
    var metadataLength;
    if (encryptedData.length > pos + 1) {
      metadataLength = encryptedData[pos];
    }
    pos += 1;
    if (metadataLength == 255 && encryptedData.length >= pos + 2) {
      metadataLength = encryptedData
          .sublist(pos, pos + 2)
          .fold<int>(0, (acc, el) => (acc << 8) + el);
    }
    return CryptorHeaderV1(utf8.decode(identifier), metadataLength);
  }
}

class CryptorHeaderV1 {
  static const VERSION = 1;
  final String _identifier;
  final int _metadataLength;

  CryptorHeaderV1(this._identifier, this._metadataLength);

  String get identifier => _identifier;
  int get metadataLength => _metadataLength;

  int get length {
    return (CryptorHeader.SENTINEL.length +
        1 +
        CryptorHeader.IDENTIFIER_LENGTH +
        (_metadataLength < 225 ? 1 : 3) +
        _metadataLength);
  }

  List<int> get data {
    var pos = 0;
    var header = List<int>.filled(length, 0);
    header.setAll(pos, CryptorHeader.SENTINEL.codeUnits);
    pos += CryptorHeader.SENTINEL.length;
    header[pos] = VERSION;
    pos++;
    header.setAll(pos, _identifier.codeUnits);
    pos += CryptorHeader.IDENTIFIER_LENGTH;
    var metadataLength = this.metadataLength;
    if (metadataLength < 255) {
      header[pos] = metadataLength;
    } else {
      header.setAll(pos, [255, metadataLength >> 8, metadataLength & 0xff]);
    }
    return header;
  }
}

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
