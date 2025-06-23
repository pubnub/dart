import 'dart:convert';
import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '../net/fake_net.dart';
part 'fixtures/files.dart';

void main() {
  late PubNub pubnub;
  var keyset =
      Keyset(subscribeKey: 'test', publishKey: 'test', userId: UserId('test'));
  group('DX [file]', () {
    setUp(() {
      pubnub = PubNub(
        defaultKeyset: keyset,
        networking: FakeNetworkingModule(),
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

    group('Input validation security tests', () {
      test('getFileUrl should reject dangerous channel names', () {
        expect(() => pubnub.files.getFileUrl('../channel', 'fileId', 'fileName'),
               throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', '../fileId', 'fileName'),
               throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', 'fileId', '../fileName'),
               throwsA(isA<FileValidationException>()));
      });

      test('getFileUrl should reject dangerous file IDs', () {
        expect(() => pubnub.files.getFileUrl('channel', '../../etc/passwd', 'fileName'),
               throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', 'file${String.fromCharCode(0)}id', 'fileName'),
               throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', '..', 'fileName'),
               throwsA(isA<FileValidationException>()));
      });

      test('getFileUrl should reject dangerous file names', () {
        expect(() => pubnub.files.getFileUrl('channel', 'fileId', '../../config.ini'),
               throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', 'fileId', 'file${String.fromCharCode(10)}.txt'),
               throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', 'fileId', 'CON'),
               throwsA(isA<FileValidationException>()));
      });

      test('should accept valid inputs', () {
        // These should not throw exceptions during validation
        expect(() => pubnub.files.getFileUrl('valid-channel', 'valid-file-id', 'valid-file.txt'),
               returnsNormally);
        expect(() => pubnub.files.getFileUrl('channel_123', 'file-id-456', 'document.pdf'),
               returnsNormally);
        expect(() => pubnub.files.getFileUrl('test.channel', 'abc123', 'image.jpg'),
               returnsNormally);
      });

      test('should handle edge cases properly', () {
        // Test with maximum allowed lengths
        var maxChannel = 'a' * 255;
        var maxFileId = 'b' * 255;
        var maxFileName = 'c' * 255;
        
        expect(() => pubnub.files.getFileUrl(maxChannel, maxFileId, maxFileName),
               returnsNormally);
        
        // Test with one character over the limit
        var overLimitChannel = 'a' * 256;
        expect(() => pubnub.files.getFileUrl(overLimitChannel, 'fileId', 'fileName'),
               throwsA(isA<FileValidationException>()));
      });
    });
  });
}
