import 'dart:convert';
import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/dx/files/files.dart';
import 'package:pubnub/src/dx/_endpoints/files.dart';

import '../net/fake_net.dart';

part 'fixtures/files.dart';

void main() {
  PubNub pubnub;
  var keyset = Keyset(subscribeKey: 'test', publishKey: 'test');
  group('DX [file]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(keyset, name: 'default', useAsDefault: true);
    });

    test('#listFiles', () async {
      when(
        path:
            'v1/files/test/channels/channel/files?limit=10&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _listFilesSuccessResponse);

      var result = await pubnub.files.listFiles('channel', limit: 10);
      expect(result, isA<ListFilesResult>());
      expect(result.filesDetail, isA<List<FileDetail>>());
      expect(result.next, isA<String>());
      expect(result.count, equals(100));
    });

    test('#publishFileMessage success', () async {
      when(
        path: _publishFileMessageUrl1,
        method: 'GET',
      ).then(status: 200, body: _publishFileMessageSuccessResponse);
      var message =
          FileMessage(FileInfo('some', 'cat_file.jpg'), message: 'msg');
      var result = await pubnub.files.publishFileMessage('channel', message);
      expect(result, isA<PublishFileMessageResult>());
    });

    test('#publishFileMessage withEncryption', () async {
      when(
        path: _publishFileMessageUrlEncryption,
        method: 'GET',
      ).then(status: 200, body: _publishFileMessageSuccessResponse);
      var message =
          FileMessage(FileInfo('some', 'cat_file.jpg'), message: 'msg');
      var result = await pubnub.files.publishFileMessage('channel', message,
          cipherKey: CipherKey.fromUtf8('cipherKey'));
      expect(result, isA<PublishFileMessageResult>());
    });

    test('#publishFileMessage withEncryption defaultKeyset', () async {
      pubnub = PubNub(
          networking: FakeNetworkingModule(),
          defaultKeyset: Keyset(
              subscribeKey: 'test',
              publishKey: 'test',
              cipherKey: CipherKey.fromUtf8('cipherKey')));
      when(
        path: _publishFileMessageUrlEncryption,
        method: 'GET',
      ).then(status: 200, body: _publishFileMessageSuccessResponse);
      var message =
          FileMessage(FileInfo('some', 'cat_file.jpg'), message: 'msg');
      var result = await pubnub.files.publishFileMessage('channel', message);
      expect(result, isA<PublishFileMessageResult>());
    });

    test('#publishFileMessage cipherKey precedence', () async {
      pubnub = PubNub(
          networking: FakeNetworkingModule(),
          defaultKeyset: Keyset(
              subscribeKey: 'test',
              publishKey: 'test',
              cipherKey: CipherKey.fromUtf8('default_cipherKey')));
      when(
        path: _publishFileMessageUrlEncryption,
        method: 'GET',
      ).then(status: 200, body: _publishFileMessageSuccessResponse);
      var message =
          FileMessage(FileInfo('some', 'cat_file.jpg'), message: 'msg');
      var result = await pubnub.files.publishFileMessage('channel', message,
          cipherKey: CipherKey.fromUtf8('cipherKey'));
      expect(result, isA<PublishFileMessageResult>());
    });

    test('#publishFileMessage failure', () async {
      when(
        path: _publishFileMessageUrl1,
        method: 'GET',
      ).then(status: 200, body: _publishFileMessageFailureResponse);
      var message =
          FileMessage(FileInfo('some', 'cat_file.jpg'), message: 'msg');
      var result = await pubnub.files.publishFileMessage('channel', message);
      expect(result, isA<PublishFileMessageResult>());
      expect(result.isError, equals(true));
    });

    test('#DeleteFile', () async {
      when(
        path:
            'v1/files/test/channels/channel/files/5a3eb38c-483a-4b25-ac01-c4e20deba6d6/cat_file.jpg?pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'DELETE',
      ).then(status: 200, body: _deleteFileResponse);

      var result = await pubnub.files.deleteFile(
          'channel', '5a3eb38c-483a-4b25-ac01-c4e20deba6d6', 'cat_file.jpg');
      expect(result, isA<DeleteFileResult>());
    });
    test('#SendFile', () async {
      when(
              path: _generateFileUploadUrl,
              method: 'POST',
              body: '{"name":"cat_file.jpg"}')
          .then(status: 200, body: _generateFileUploadUrlResponse);

      when(
              path: 'https://pubnub-test-config.s3.amazonaws.com',
              method: 'POST',
              body: _sendFileResponse)
          .then(status: 204, body: '');

      when(
        path: _publishFileMessageUrl2,
        method: 'GET',
      ).then(status: 200, body: _publishFileMessageSuccessResponse);

      var result = await pubnub.files.sendFile(
          'channel', 'cat_file.jpg', [0, 1, 2, 3],
          fileMessage: 'msg', keyset: keyset);
      expect(result, isA<PublishFileMessageResult>());
    });

    test('#SendFile #FileMessagePublish retry', () async {
      var keyset = Keyset(subscribeKey: 'test', publishKey: 'test');
      when(
              path: _generateFileUploadUrl,
              method: 'POST',
              body: '{"name":"cat_file.jpg"}')
          .then(status: 200, body: _generateFileUploadUrlResponse);
      when(
              path: 'https://pubnub-test-config.s3.amazonaws.com',
              method: 'POST',
              body: _sendFileResponse)
          .then(status: 204, body: '');
      when(
        path: _publishFileMessageUrl2,
        method: 'GET',
      ).then(status: 400, body: _publishFileMessageFailureResponse);
      var result = await pubnub.files.sendFile(
          'channel', 'cat_file.jpg', [0, 1, 2, 3],
          fileMessage: 'msg', keyset: keyset);
      expect(result, isA<PublishFileMessageResult>());
      expect(result.fileInfo, isNotNull);
    });

    test('#Download File', () async {
      when(path: _downloadFileUrl, method: 'GET')
          .then(status: 200, body: [01, 02]);
      var result = await pubnub.files.downloadFile(
          'channel', '5a3eb38c-483a-4b25-ac01-c4e20deba6d6', 'cat_file.jpg');

      expect(result, isA<DownloadFileResult>());
    });
    test('#getFileUrl', () async {
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
  });
}
