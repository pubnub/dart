import 'dart:convert' show utf8;

import 'package:pubnub/core.dart';

/// @nodoc
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
      if (utf8.decode(sentinel, allowMalformed: true) != SENTINEL) return null;
    }

    if (encryptedData.length >= 5) {
      version = encryptedData[4];
    } else {
      throw CryptoException('decryption error: invalid or no header version.');
    }
    if (version > MAX_VERSION) {
      throw CryptoException(
          'unknown cryptor error: header version is higher than supported versions.');
    }

    var identifier;
    var pos = 5 + IDENTIFIER_LENGTH;
    if (encryptedData.length >= pos) {
      identifier = encryptedData.sublist(5, pos).toList();
    } else {
      throw CryptoException(
          'decryption error: invalid or No identifier found.');
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

/// @nodoc
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
