import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/crypto/aes_gcm_cryptor.dart';
import 'package:pubnub/src/crypto/cryptorHeader.dart';
import 'package:test/test.dart';

void main() {
  // Shared PNED payloads. Metadata is the nonce; the tag follows the ciphertext.
  final vectors = <_Vector>[
    _Vector(
      name: 'hello',
      cipherKey: 'enigma',
      plaintext: utf8.encode('Hello world'),
      payloadHex:
          '504e4544014143474d0c0102030405060708090a0b0cea1b5780788b593294f898dabd1d02d7219c77218ad262c4a9aecc',
    ),
    _Vector(
      name: 'unicode',
      cipherKey: 'enigma',
      plaintext: utf8.encode('héllo 你好'),
      payloadHex:
          '504e4544014143474d0c111111111111111111111111d138fbfc4bd0c337e29d9f2c98a5dd072360f4433e2979f440fc7827b3',
    ),
    _Vector(
      name: 'binary',
      cipherKey: 'myCipherKey',
      plaintext: [0x00, 0xff, 0x7f, 0x80],
      payloadHex:
          '504e4544014143474d0c000102030405060708090a0bc411f0f18fefca7becf7235b4d09b970d4d56d19',
    ),
    _Vector(
      name: 'json-emoji',
      cipherKey: 'enigma',
      plaintext: utf8.encode('{"text":"Hello, 世界! 🌍","n":42}'),
      payloadHex:
          '504e4544014143474d0cffffffffffffffffffffffff0d54b73ce2509d4e7655043f5b103cb4f1e78738a73a2f56109813955359b4784774de1954f835d4d739805631c5cdcc3467607259',
    ),
    _Vector(
      name: 'one-block',
      cipherKey: 'enigma',
      plaintext: utf8.encode('0123456789abcdef'),
      payloadHex:
          '504e4544014143474d0c8f5a2d1b6e9c4ef0a37d83b9fd24a488008bd084305aaee605b349028c21b92d48f4dd5c71e99dce881c2ec9',
    ),
    _Vector(
      name: 'multi-block-json',
      cipherKey: 'enigma',
      plaintext: utf8.encode(
          '{"text":"Hello, 世界! 🌍","n":42,"list":[1,2,3],"nested":{"ok":true}}'),
      payloadHex:
          '504e4544014143474d0cffffffffffffffffffffffff0d54b73ce2509d4e7655043f5b103cb4f1e78738a73a2f56109813955359b4784774de19050b4f14f7a439a859ac6c327856fe1af874bbe888945c603004176ddab22578e407663346d307669e83fa4c9a8b13743a07a21b7f',
    ),
    _Vector(
      name: 'unicode-key-multiblock',
      cipherKey: 'ключ 🔑 key',
      plaintext: utf8.encode(
          'Line one\n\tLine two with "quotes" & symbols <>/\\ — spans several AES blocks.'),
      payloadHex:
          '504e4544014143474d0c000000000000000000000000326052d9ff1b757ed8810f5d6f87a7c021920eb09b82e47049efecf5094f6f5837691e9fb66539dfc47d434cc01b783527c4d62ae2d8163043f86dc7ac405b90971ceaa07134add2be50dfd60f8390572d9b05255f3097614e888fcca4',
    ),
    _Vector(
      name: 'single-byte',
      cipherKey: 'customKey',
      plaintext: utf8.encode('a'),
      payloadHex:
          '504e4544014143474d0ca1a2a3a4a5a6a7a8a9aaabacfbeef1ccce8f5a09087348786b99b75076',
    ),
    _Vector(
      name: 'empty',
      cipherKey: 'enigma',
      plaintext: <int>[],
      payloadHex:
          '504e4544014143474d0c090807060504030201000102d2cc905e1cc396312f67a8be4c17fb43',
    ),
  ];

  group('Crypto [aes-gcm]', () {
    test('known ciphertexts decrypt with both factories', () {
      for (var vector in vectors) {
        var payload = hex.decode(vector.payloadHex);
        expect(utf8.decode(payload.sublist(5, 9)), 'ACGM', reason: vector.name);
        expect(payload[9], 0x0c, reason: vector.name);

        for (var module in _modules(vector.cipherKey)) {
          expect(module.decrypt(payload), vector.plaintext,
              reason: '${vector.name} ${module.runtimeType}');
          expect(module.decryptWithKey(_key(vector.cipherKey), payload),
              vector.plaintext,
              reason: '${vector.name} decryptWithKey');
        }
      }
    });

    test('files.decryptFile reads ACGM when only a cipher key is passed', () {
      var client = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'demo',
          publishKey: 'demo',
          userId: UserId('gcm-test'),
        ),
      );
      for (var vector in vectors) {
        expect(
          client.files.decryptFile(
            hex.decode(vector.payloadHex),
            cipherKey: _key(vector.cipherKey),
          ),
          vector.plaintext,
          reason: vector.name,
        );
      }
    });

    test('files.decryptFile accepts the same payloads', () {
      for (var vector in vectors) {
        var payload = hex.decode(vector.payloadHex);
        var key = _key(vector.cipherKey);
        for (var module in _modules(vector.cipherKey)) {
          var client = _client(module);
          expect(client.files.decryptFile(payload), vector.plaintext,
              reason: '${vector.name} module key');
          expect(client.files.decryptFile(payload, cipherKey: key),
              vector.plaintext,
              reason: '${vector.name} cipherKey override');
        }
      }
    });

    test('a cipher-key override decrypts with that key', () {
      var vector = vectors.first;
      var payload = hex.decode(vector.payloadHex);
      var module =
          CryptoModule.aesCbcCryptoModule(_key('different-module-key'));

      expect(
        module.decryptWithKey(_key(vector.cipherKey), payload),
        vector.plaintext,
      );
      expect(
        () => module.decrypt(payload),
        throwsA(_decryptionError),
      );

      var client = _client(module);
      expect(
        client.files.decryptFile(payload, cipherKey: _key(vector.cipherKey)),
        vector.plaintext,
      );
    });

    test('a short ACGM header fails as a decryption error', () {
      var payload = <int>[
        0x50, 0x4e, 0x45, 0x44, // PNED
        0x01, // version
        0x41, 0x43, 0x47, 0x4d, // ACGM
        0x0c, // metadata length 12
        0x01, // one nonce byte
      ];
      for (var module in _modules('enigma')) {
        expect(() => module.decrypt(payload), throwsA(_decryptionError));
        expect(
          () => module.decryptWithKey(_key('enigma'), payload),
          throwsA(_decryptionError),
        );
        expect(
          () => _client(module).files.decryptFile(payload),
          throwsA(_decryptionError),
        );
      }
    });

    test('a 10-byte header ending on the metadata-size byte parses', () {
      // PNED, version, ACRH, and a size of 0. The size byte is the last byte.
      var payload = <int>[
        0x50, 0x4e, 0x45, 0x44, // PNED
        0x01, // version
        0x41, 0x43, 0x52, 0x48, // ACRH
        0x00, // metadata length 0
      ];

      var header = CryptorHeader.tryParse(payload);

      expect(header, isNotNull);
      expect(header!.identifier, 'ACRH');
      expect(header.metadataLength, 0);
      expect(header.length, payload.length);
    });

    test('a malformed PNED header throws CryptoException', () {
      var missingMetadataSize = <int>[
        0x50, 0x4e, 0x45, 0x44, // PNED
        0x01, // version
        0x41, 0x43, 0x47, 0x4d, // ACGM
      ];
      var invalidIdentifier = <int>[
        0x50, 0x4e, 0x45, 0x44, // PNED
        0x01, // version
        0xff, 0xff, 0xff, 0xff, // not UTF-8
        0x00, // metadata length 0
      ];
      for (var module in _modules('enigma')) {
        for (var payload in [missingMetadataSize, invalidIdentifier]) {
          expect(
              () => module.decrypt(payload), throwsA(isA<CryptoException>()));
          expect(
            () => module.decryptWithKey(_key('enigma'), payload),
            throwsA(isA<CryptoException>()),
          );
        }
      }
    });

    test('invalid payloads fail closed', () {
      var payload = hex.decode(vectors.first.payloadHex);
      var cryptor = AesGcmCryptor(_key('enigma'));
      var module = CryptoModule.aesCbcCryptoModule(_key('enigma'));

      var tampered = [...payload]..[payload.length - 1] ^= 0xff;
      expect(() => module.decrypt(tampered), throwsA(_decryptionError));
      expect(
        () => CryptoModule.legacyCryptoModule(_key('enigma')).decrypt(tampered),
        throwsA(_decryptionError),
      );

      expect(
        () => cryptor.decrypt(EncryptedData.from(
          payload.sublist(22, payload.length - 1),
          payload.sublist(10, 22),
        )),
        throwsA(_decryptionError),
      );
      expect(
        () => AesGcmCryptor(_key('other-key')).decrypt(EncryptedData.from(
          payload.sublist(22),
          payload.sublist(10, 22),
        )),
        throwsA(_decryptionError),
      );
      expect(
        () => cryptor.decrypt(EncryptedData.from(
          payload.sublist(22),
          payload.sublist(10, 21),
        )),
        throwsA(_decryptionError),
      );
      expect(
        () => cryptor.decrypt(EncryptedData.from(
          payload.sublist(22, 22 + 15),
          payload.sublist(10, 22),
        )),
        throwsA(_decryptionError),
      );

      var failure = _capture(() => module.decrypt(tampered));
      expect(failure.message, 'decryption error');
      expect(failure.message.contains('enigma'), isFalse);
      expect(failure.message.contains('Hello world'), isFalse);
    });

    test('encryption stays on the factory cryptor', () {
      var plain = utf8.encode('Hello world');
      var cbc = CryptoModule.aesCbcCryptoModule(_key('enigma'));
      var legacy = CryptoModule.legacyCryptoModule(_key('enigma'));

      var cbcEncrypted = cbc.encrypt(plain);
      expect(CryptorHeader.tryParse(cbcEncrypted)!.identifier, 'ACRH');
      expect(cbc.decrypt(cbcEncrypted), plain);

      var legacyEncrypted = legacy.encrypt(plain);
      expect(_headerId(legacyEncrypted), isNot('ACGM'));
      expect(legacy.decrypt(legacyEncrypted), plain);

      var overrideKey = _key('override-key');
      var overridden = cbc.encryptWithKey(overrideKey, plain);
      expect(_headerId(overridden), isNot('ACGM'));
      expect(cbc.decryptWithKey(overrideKey, overridden), plain);

      var client = _client(cbc);
      var file = client.files.encryptFile(plain, cipherKey: overrideKey);
      expect(_headerId(file), isNot('ACGM'));
      expect(
        client.files.decryptFile(file, cipherKey: overrideKey),
        plain,
      );

      expect(
        () => AesGcmCryptor(_key('enigma')).encrypt(plain),
        throwsA(isA<CryptoException>().having((e) => e.message, 'message',
            'encryption error: AES-GCM encryption is not available')),
      );
      expect(
        () => AesGcmCryptor(_key('enigma')).encryptFileData(plain),
        throwsA(isA<CryptoException>().having((e) => e.message, 'message',
            'encryption error: AES-GCM encryption is not available')),
      );
    });
  });
}

CipherKey _key(String value) => CipherKey.fromUtf8(value);

List<CryptoModule> _modules(String cipherKey) {
  var key = _key(cipherKey);
  return [
    CryptoModule.aesCbcCryptoModule(key),
    CryptoModule.legacyCryptoModule(key),
  ];
}

PubNub _client(CryptoModule module) {
  return PubNub(
    defaultKeyset: Keyset(
      subscribeKey: 'demo',
      publishKey: 'demo',
      userId: UserId('gcm-test'),
    ),
    crypto: module,
  );
}

String? _headerId(List<int> encrypted) {
  try {
    return CryptorHeader.tryParse(encrypted)?.identifier;
  } on CryptoException {
    return null;
  }
}

Matcher _decryptionError = isA<CryptoException>()
    .having((e) => e.message, 'message', 'decryption error');

CryptoException _capture(void Function() body) {
  try {
    body();
  } on CryptoException catch (e) {
    return e;
  }
  fail('expected CryptoException');
}

class _Vector {
  final String name;
  final String cipherKey;
  final List<int> plaintext;
  final String payloadHex;

  _Vector({
    required this.name,
    required this.cipherKey,
    required this.plaintext,
    required this.payloadHex,
  });
}
