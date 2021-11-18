import 'dart:convert';
import 'package:pubnub/crypto.dart';
import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import '../net/fake_net.dart';
part 'fixtures/files.dart';

void main() {
  late PubNub pubnub;
  var keyset =
      Keyset(subscribeKey: 'test', publishKey: 'test', uuid: UUID('test'));
  group('DX [file]', () {
    setUp(() {
      pubnub = PubNub(
        defaultKeyset: keyset,
        networking: FakeNetworkingModule(),
        crypto: CryptoModule(
          defaultConfiguration:
              CryptoConfiguration(useRandomInitializationVector: false),
        ),
      );
    });

    test('#getFileUrl', () {
      var result = pubnub.files.getFileUrl('channel', 'fileId', 'fileName');
      expect(result, isA<Uri>());
      expect(result.toString(), equals(_getFileUrl));
    });

    test('file encryption mechanism', () async {
      var input = 'hello there!';
      var encryptedData = pubnub.files.encryptFile(utf8.encode(input),
          cipherKey: CipherKey.fromUtf8('secret'));
      var decryptedData = pubnub.files
          .decryptFile(encryptedData, cipherKey: CipherKey.fromUtf8('secret'));
      expect(utf8.decode(decryptedData), equals(input));
    });

    test('#getFileUrl with secretKey and auth', () {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test',
              publishKey: 'test',
              secretKey: 'test',
              authKey: 'test',
              uuid: UUID('test')));
      var result =
          pubnub.files.getFileUrl('my_channel', 'file-id', 'cat_picture.jpg');
      expect(result.queryParameters, contains('signature'));
      expect(result.queryParameters, contains('auth'));
    });
  });
}
