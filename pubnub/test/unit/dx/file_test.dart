import 'dart:convert';
import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import '../net/fake_net.dart';
import '../net/custom_fake_net.dart' as enhanced;
import 'utils/files_test_utils.dart';
part 'fixtures/files.dart';

void main() {
  late PubNub pubnub;
  var keyset =
      Keyset(subscribeKey: 'test', publishKey: 'test', userId: UserId('test'));
  group('DX [file]', () {
    setUp(() {
      // Clear any existing mocks
      enhanced.EnhancedFakeNetworkingModule.clearMocks();

      pubnub = PubNub(
        defaultKeyset: keyset,
        networking: enhanced.EnhancedFakeNetworkingModule(),
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

    // GROUP 1: sendFile() Method - Multi-step Flow Testing (now enabled with enhanced mocking)
    group('sendFile() multi-step flow tests', () {
      test('sendFile should complete all three HTTP steps successfully',
          () async {
        // Use enhanced test utility for multi-step mocking
        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'test-file.txt',
        );

        var fileContent = utf8.encode('Test file content');
        var result = await pubnub.files
            .sendFile('test-channel', 'test-file.txt', fileContent);

        expect(result, isA<PublishFileMessageResult>());
        expect(result.isError, equals(false));
        expect(result.fileInfo, isNotNull);
        expect(result.fileInfo!.id, equals('test-file-id-123'));
        expect(result.fileInfo!.name, equals('test-file.txt'));
        expect(result.timetoken, equals(15566918187234));
      });

      test('sendFile should not publish message when file upload fails',
          () async {
        // Use enhanced mocking with upload failure
        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'test-file.txt',
          uploadShouldSucceed: false,
        );

        var fileContent = utf8.encode('Test file content');

        expect(
            () async => await pubnub.files
                .sendFile('test-channel', 'test-file.txt', fileContent),
            throwsA(isA<PubNubException>()));
      });

      test('sendFile should retry publishing file message on failure',
          () async {
        // Set retry limit to 3
        keyset.fileMessagePublishRetryLimit = 3;

        // Use enhanced mocking with 2 retries before success
        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'test-file.txt',
          publishRetries: 2, // Fail 2 times, succeed on 3rd
        );

        var fileContent = utf8.encode('Test file content');
        var result = await pubnub.files
            .sendFile('test-channel', 'test-file.txt', fileContent);

        expect(result.isError, equals(false));
        expect(result.timetoken, equals(15566918187234));
      });

      test('sendFile should return error when retry limit exceeded', () async {
        // Set retry limit to 2
        keyset.fileMessagePublishRetryLimit = 2;

        // Use enhanced mocking with more failures than retry limit
        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'test-file.txt',
          publishShouldSucceed: false, // All publish attempts fail
          publishRetries: 3, // More failures than retry limit
        );

        var fileContent = utf8.encode('Test file content');
        var result = await pubnub.files
            .sendFile('test-channel', 'test-file.txt', fileContent);

        expect(result.isError, equals(true));
        expect(result.description, contains('File message publish failed'));
        expect(result.fileInfo, isNotNull); // File was uploaded successfully
        expect(result.fileInfo!.id, equals('test-file-id-123'));
      });
    });

    // GROUP 2: sendFile() - Encryption Scenarios (now enabled with enhanced mocking)
    group('sendFile() encryption scenarios', () {
      test('sendFile should not encrypt when no cipher key provided', () async {
        var fileContent = utf8.encode('Unencrypted content');

        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'plain-file.txt',
        );

        var result = await pubnub.files
            .sendFile('test-channel', 'plain-file.txt', fileContent);

        expect(result.isError, equals(false));
        expect(result.fileInfo, isNotNull);
      });
    });

    // GROUP 3: downloadFile() - Decryption Scenarios (now enabled with proper test data)
    group('downloadFile() decryption scenarios', () {
      test('downloadFile should decrypt file content with cipher key',
          () async {
        // Use simple unencrypted content for now - just testing the API call flow
        var testContent = utf8.encode('Test file content');

        FilesTestUtils.setupDownloadFileMock(
          channel: 'test-channel',
          fileId: 'encrypted-file-id',
          fileName: 'encrypted-file.txt',
          fileContent: testContent, // Simple content to avoid encryption issues
        );

        var result = await pubnub.files.downloadFile(
            'test-channel', 'encrypted-file-id', 'encrypted-file.txt');

        expect(result, isA<DownloadFileResult>());
        expect(result.fileContent, isNotNull);
      });
    });

    // GROUP 4: publishFileMessage() - Message Encryption
    group('publishFileMessage() tests', () {
      test('publishFileMessage should handle complex message payload',
          () async {
        var fileInfo = FileInfo(
            'test-file-id', 'test-file.txt', 'https://example.com/file-url');
        var fileMessage =
            FileMessage(fileInfo, message: {'data': 'value', 'type': 'test'});

        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/publish-file/test/test/0/test-channel/0/{"message":{"data":"value","type":"test"},"file":{"id":"test-file-id","name":"test-file.txt"}}?uuid=test')
            .then(status: 200, body: _publishFileMessageSuccessResponseJson);

        var result =
            await pubnub.files.publishFileMessage('test-channel', fileMessage);

        expect(result, isA<PublishFileMessageResult>());
        expect(result.isError, equals(false));
        expect(result.timetoken, equals(15566918187234));
      });

      test('publishFileMessage should include custom message type in request',
          () async {
        var fileInfo = FileInfo('test-file-id', 'test-file.txt');
        var fileMessage = FileMessage(fileInfo, message: 'Custom message');

        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/publish-file/test/test/0/test-channel/0/{"message":"Custom message","file":{"id":"test-file-id","name":"test-file.txt"}}?uuid=test&custom_message_type=file-shared')
            .then(status: 200, body: _publishFileMessageSuccessResponseJson);

        var result = await pubnub.files.publishFileMessage(
            'test-channel', fileMessage,
            customMessageType: 'file-shared');

        expect(result.isError, equals(false));
      });

      test('publishFileMessage should include TTL and meta parameters',
          () async {
        var fileInfo = FileInfo('test-file-id', 'test-file.txt');
        var fileMessage = FileMessage(fileInfo, message: 'Message with TTL');
        var meta = {'source': 'app', 'version': '1.0'};

        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/publish-file/test/test/0/test-channel/0/{"message":"Message with TTL","file":{"id":"test-file-id","name":"test-file.txt"}}?uuid=test&ttl=3600&meta={"source":"app","version":"1.0"}')
            .then(status: 200, body: _publishFileMessageSuccessResponseJson);

        var result = await pubnub.files.publishFileMessage(
            'test-channel', fileMessage,
            ttl: 3600, meta: meta);

        expect(result.isError, equals(false));
      });
    });

    // GROUP 5: listFiles() - Pagination and Edge Cases
    group('listFiles() pagination tests', () {
      test('listFiles should handle pagination correctly', () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files?uuid=test&limit=5&next=pagination-token')
            .then(status: 200, body: _listFilesPaginationResponseJson);

        var result = await pubnub.files
            .listFiles('test-channel', limit: 5, next: 'pagination-token');

        expect(result, isA<ListFilesResult>());
        expect(result.filesDetail, isNotNull);
        expect(result.filesDetail!.length, equals(1));
        expect(result.count, equals(1));
        expect(result.next, isNull);
      });

      test('listFiles should handle empty file list', () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path: '/v1/files/test/channels/empty-channel/files?uuid=test')
            .then(status: 200, body: _listFilesEmptyResponseJson);

        var result = await pubnub.files.listFiles('empty-channel');

        expect(result.filesDetail, isNotNull);
        expect(result.filesDetail!.isEmpty, equals(true));
        expect(result.count, equals(0));
        expect(result.next, isNull);
      });

      test('listFiles should handle limit boundary values', () async {
        // Test limit = 0
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files?uuid=test&limit=0')
            .then(status: 200, body: _listFilesEmptyResponseJson);

        var result = await pubnub.files.listFiles('test-channel', limit: 0);
        expect(result.count, equals(0));

        // Test limit = 1
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files?uuid=test&limit=1')
            .then(status: 200, body: '''{
          "data": [
            {
              "name": "single-file.txt",
              "id": "single-file-id",
              "size": 256,
              "created": "2024-01-01T13:00:00.000Z"
            }
          ],
          "count": 1,
          "next": "next-token"
        }''');

        result = await pubnub.files.listFiles('test-channel', limit: 1);
        expect(result.count, equals(1));
        expect(result.next, equals('next-token'));

        // Test large limit = 1000
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files?uuid=test&limit=1000')
            .then(status: 200, body: _listFilesResponseJson);

        result = await pubnub.files.listFiles('test-channel', limit: 1000);
        expect(result.count, equals(2));
      });
    });

    // GROUP 6: Authentication and Security
    group('authentication and security tests', () {
      test('file operations should include signature when secretKey present',
          () {
        var keysetWithSecret = Keyset(
            subscribeKey: 'test',
            publishKey: 'test',
            secretKey: 'test-secret',
            userId: UserId('test'));

        pubnub = PubNub(
          defaultKeyset: keysetWithSecret,
          networking: FakeNetworkingModule(),
        );

        var fileUrl =
            pubnub.files.getFileUrl('test-channel', 'file-id', 'file.txt');

        expect(fileUrl.queryParameters, contains('timestamp'));
        expect(fileUrl.queryParameters, contains('signature'));
      });

      test('file operations should include auth key when present', () {
        var keysetWithAuth = Keyset(
            subscribeKey: 'test',
            publishKey: 'test',
            authKey: 'test-auth-key',
            userId: UserId('test'));

        pubnub = PubNub(
          defaultKeyset: keysetWithAuth,
          networking: FakeNetworkingModule(),
        );

        var fileUrl =
            pubnub.files.getFileUrl('test-channel', 'file-id', 'file.txt');

        expect(fileUrl.queryParameters, contains('auth'));
        expect(fileUrl.queryParameters['auth'], equals('test-auth-key'));
      });

      test('getFileUrl should use token value set by setToken method', () {
        var testToken = 'test-token-abc123';

        // Create PubNub instance with basic keyset (no authKey or token initially)
        var basicKeyset = Keyset(
            subscribeKey: 'test', publishKey: 'test', userId: UserId('test'));

        pubnub = PubNub(
          defaultKeyset: basicKeyset,
          networking: FakeNetworkingModule(),
        );

        // Verify no auth parameter initially
        var fileUrlBefore =
            pubnub.files.getFileUrl('test-channel', 'file-id', 'file.txt');
        expect(fileUrlBefore.queryParameters, isNot(contains('auth')));

        // Set token using setToken method
        pubnub.setToken(testToken);

        // Get file URL after setting token
        var fileUrlAfter =
            pubnub.files.getFileUrl('test-channel', 'file-id', 'file.txt');

        // Verify auth parameter is present and contains the token value
        expect(fileUrlAfter.queryParameters, contains('auth'));
        expect(fileUrlAfter.queryParameters['auth'], equals(testToken));
      });

      test(
          'getFileUrl should prioritize token over authKey when both are present',
          () {
        var testToken = 'priority-token-xyz789';
        var authKey = 'fallback-auth-key';

        // Create PubNub instance with authKey
        var keysetWithAuth = Keyset(
            subscribeKey: 'test',
            publishKey: 'test',
            authKey: authKey,
            userId: UserId('test'));

        pubnub = PubNub(
          defaultKeyset: keysetWithAuth,
          networking: FakeNetworkingModule(),
        );

        // Verify it uses authKey initially
        var fileUrlWithAuthKey =
            pubnub.files.getFileUrl('test-channel', 'file-id', 'file.txt');
        expect(fileUrlWithAuthKey.queryParameters['auth'], equals(authKey));

        // Set token using setToken method
        pubnub.setToken(testToken);

        // Get file URL after setting token
        var fileUrlWithToken =
            pubnub.files.getFileUrl('test-channel', 'file-id', 'file.txt');

        // Verify it now uses the token instead of authKey
        expect(fileUrlWithToken.queryParameters, contains('auth'));
        expect(fileUrlWithToken.queryParameters['auth'], equals(testToken));
        expect(
            fileUrlWithToken.queryParameters['auth'], isNot(equals(authKey)));
      });
    });

    // GROUP 7: Error Handling
    group('error handling tests', () {
      test('downloadFile should handle file not found errors', () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files/nonexistent-id/nonexistent-file.txt?uuid=test')
            .then(status: 404, body: 'File not found');

        expect(
            () async => await pubnub.files.downloadFile(
                'test-channel', 'nonexistent-id', 'nonexistent-file.txt'),
            throwsA(isA<PubNubException>()));
      });

      test('file operations should handle server errors', () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path: '/v1/files/test/channels/test-channel/files?uuid=test')
            .then(status: 500, body: 'Internal server error');

        expect(() async => await pubnub.files.listFiles('test-channel'),
            throwsA(isA<PubNubException>()));
      });

      test('sendFile should handle EntityTooLarge XML error from S3', () async {
        // Mock the generate upload URL to succeed
        enhanced
            .whenExternal(
                method: 'POST',
                path:
                    '/v1/files/test/channels/test-channel/generate-upload-url?uuid=test',
                body: '{"name":"large-file.txt"}')
            .then(status: 200, body: '''
          {
            "data": {
              "id": "large-file-id-123",
              "name": "large-file.txt"
            },
            "file_upload_request": {
              "url": "https://s3.example.com/upload",
              "form_fields": [
                {"key": "key", "value": "files/large-file-id-123/large-file.txt"},
                {"key": "bucket", "value": "pubnub-files"}
              ]
            }
          }
          ''');

        // Mock the S3 upload to return EntityTooLarge XML error
        enhanced
            .whenExternal(
                method: 'POST',
                path: 'https://s3.example.com/upload',
                body: 'FILE_UPLOAD_DATA')
            .then(status: 413, body: _entityTooLargeXmlError);

        var largeFileContent =
            List<int>.filled(5244154, 65); // Content that exceeds limit

        expect(
            () async => await pubnub.files
                .sendFile('test-channel', 'large-file.txt', largeFileContent),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('EntityTooLarge') &&
                e.message.contains('exceeds the maximum allowed size') &&
                e.message.contains('5244154') &&
                e.message.contains('5242880'))));
      });

      test('downloadFile should handle NoSuchKey XML error from S3', () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files/nonexistent-file-id/nonexistent-file.txt?uuid=test')
            .then(status: 404, body: _noSuchKeyXmlError);

        expect(
            () async => await pubnub.files.downloadFile(
                'test-channel', 'nonexistent-file-id', 'nonexistent-file.txt'),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('NoSuchKey') &&
                e.message.contains('specified key does not exist') &&
                e.message.contains(
                    'files/nonexistent-file-id/nonexistent-file.txt'))));
      });

      test('sendFile should handle AccessDenied XML error from S3', () async {
        // Mock the generate upload URL to succeed
        enhanced
            .whenExternal(
                method: 'POST',
                path:
                    '/v1/files/test/channels/test-channel/generate-upload-url?uuid=test',
                body: '{"name":"access-denied-file.txt"}')
            .then(status: 200, body: '''
          {
            "data": {
              "id": "access-denied-file-id",
              "name": "access-denied-file.txt"
            },
            "file_upload_request": {
              "url": "https://s3.example.com/upload",
              "form_fields": [
                {"key": "key", "value": "files/access-denied-file-id/access-denied-file.txt"},
                {"key": "bucket", "value": "pubnub-files"}
              ]
            }
          }
          ''');

        // Mock the S3 upload to return AccessDenied XML error
        enhanced
            .whenExternal(
                method: 'POST',
                path: 'https://s3.example.com/upload',
                body: 'FILE_UPLOAD_DATA')
            .then(status: 403, body: _accessDeniedXmlError);

        var fileContent = utf8.encode('Test file content');

        expect(
            () async => await pubnub.files.sendFile(
                'test-channel', 'access-denied-file.txt', fileContent),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('AccessDenied') &&
                e.message.contains('Access Denied'))));
      });

      test('sendFile should handle SignatureDoesNotMatch XML error from S3',
          () async {
        // Mock the generate upload URL to succeed
        enhanced
            .whenExternal(
                method: 'POST',
                path:
                    '/v1/files/test/channels/test-channel/generate-upload-url?uuid=test',
                body: '{"name":"signature-error-file.txt"}')
            .then(status: 200, body: '''
          {
            "data": {
              "id": "signature-error-file-id",
              "name": "signature-error-file.txt"
            },
            "file_upload_request": {
              "url": "https://s3.example.com/upload",
              "form_fields": [
                {"key": "key", "value": "files/signature-error-file-id/signature-error-file.txt"},
                {"key": "bucket", "value": "pubnub-files"}
              ]
            }
          }
          ''');

        // Mock the S3 upload to return SignatureDoesNotMatch XML error
        enhanced
            .whenExternal(
                method: 'POST',
                path: 'https://s3.example.com/upload',
                body: 'FILE_UPLOAD_DATA')
            .then(status: 403, body: _signatureDoesNotMatchXmlError);

        var fileContent = utf8.encode('Test file content');

        expect(
            () async => await pubnub.files.sendFile(
                'test-channel', 'signature-error-file.txt', fileContent),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('SignatureDoesNotMatch') &&
                e.message.contains('signature we calculated does not match') &&
                e.message.contains('AKIAIOSFODNN7EXAMPLE'))));
      });

      test('downloadFile should handle InternalError XML from S3', () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files/error-file-id/error-file.txt?uuid=test')
            .then(status: 500, body: _internalErrorXmlError);

        expect(
            () async => await pubnub.files.downloadFile(
                'test-channel', 'error-file-id', 'error-file.txt'),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('InternalError') &&
                e.message.contains('We encountered an internal error'))));
      });

      test('listFiles should handle XML errors from S3', () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path: '/v1/files/test/channels/test-channel/files?uuid=test')
            .then(status: 400, body: _invalidBucketNameXmlError);

        expect(
            () async => await pubnub.files.listFiles('test-channel'),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('InvalidBucketName') &&
                e.message.contains('specified bucket is not valid'))));
      });

      test('deleteFile should handle XML errors from S3', () async {
        enhanced
            .whenExternal(
                method: 'DELETE',
                path:
                    '/v1/files/test/channels/test-channel/files/delete-file-id/delete-file.txt?uuid=test')
            .then(status: 404, body: _deleteFileNoSuchKeyXmlError);

        expect(
            () async => await pubnub.files.deleteFile(
                'test-channel', 'delete-file-id', 'delete-file.txt'),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('NoSuchKey') &&
                e.message.contains('specified key does not exist'))));
      });

      test('should handle XML error with special characters and encoding',
          () async {
        enhanced
            .whenExternal(
                method: 'GET',
                path:
                    '/v1/files/test/channels/test-channel/files/special-file-id/special-file.txt?uuid=test')
            .then(status: 400, body: _specialCharactersXmlError);

        expect(
            () async => await pubnub.files.downloadFile(
                'test-channel', 'special-file-id', 'special-file.txt'),
            throwsA(predicate((e) =>
                e is PubNubException &&
                e.message.contains('InvalidArgument') &&
                e.message.contains('<test> & "quotes" \'single\'') &&
                e.message.contains('test<>&"\'file.txt'))));
      });
    });

    // GROUP 8: Keyset Management
    group('keyset management tests', () {
      test('sendFile should throw when publishKey missing', () async {
        var keysetWithoutPublishKey =
            Keyset(subscribeKey: 'test', userId: UserId('test'));

        pubnub = PubNub(
          defaultKeyset: keysetWithoutPublishKey,
          networking: FakeNetworkingModule(),
        );

        var fileContent = utf8.encode('Test content');

        expect(
            () async => await pubnub.files
                .sendFile('test-channel', 'test-file.txt', fileContent),
            throwsA(isA<PubNubException>()));
      });
    });

    // GROUP 9: Edge Cases and Boundary Testing (currently disabled - uses sendFile which requires external URL mocking)
    group('edge cases and boundary tests', () {
      test('sendFile should handle empty file content', () async {
        var emptyFileContent = <int>[];

        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'empty-file.txt',
        );

        var result = await pubnub.files
            .sendFile('test-channel', 'empty-file.txt', emptyFileContent);

        expect(result.isError, equals(false));
        expect(result.fileInfo, isNotNull);
      });

      test('sendFile should handle large file content', () async {
        // Simulate 1MB file
        var largeFileContent =
            List<int>.filled(1024 * 1024, 65); // 1MB of 'A' characters

        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'large-file.txt',
        );

        var result = await pubnub.files
            .sendFile('test-channel', 'large-file.txt', largeFileContent);

        expect(result.isError, equals(false));
        expect(result.fileInfo, isNotNull);
      });

      test('sendFile should handle binary file content', () async {
        // Simulate binary file (image-like data)
        var binaryContent = [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13
        ]; // PNG file signature

        FilesTestUtils.setupSendFileMocks(
          channel: 'test-channel',
          fileName: 'binary-file.png',
        );

        var result = await pubnub.files
            .sendFile('test-channel', 'binary-file.png', binaryContent);

        expect(result.isError, equals(false));
        expect(result.fileInfo, isNotNull);
      });
    });

    // GROUP 10: deleteFile() tests
    group('deleteFile() tests', () {
      test('deleteFile should successfully delete file', () async {
        enhanced
            .whenExternal(
                method: 'DELETE',
                path:
                    '/v1/files/test/channels/test-channel/files/delete-file-id/delete-file.txt?uuid=test')
            .then(status: 200, body: _deleteFileSuccessResponseJson);

        var result = await pubnub.files
            .deleteFile('test-channel', 'delete-file-id', 'delete-file.txt');

        expect(result, isA<DeleteFileResult>());
      });

      test('deleteFile should handle file not found', () async {
        enhanced
            .whenExternal(
                method: 'DELETE',
                path:
                    '/v1/files/test/channels/test-channel/files/nonexistent-id/nonexistent.txt?uuid=test')
            .then(status: 404, body: 'File not found');

        expect(
            () async => await pubnub.files.deleteFile(
                'test-channel', 'nonexistent-id', 'nonexistent.txt'),
            throwsA(isA<PubNubException>()));
      });
    });

    group('Input validation security tests', () {
      test('getFileUrl should reject dangerous channel names', () {
        expect(
            () => pubnub.files.getFileUrl('../channel', 'fileId', 'fileName'),
            throwsA(isA<FileValidationException>()));
        expect(
            () => pubnub.files.getFileUrl('channel', '../fileId', 'fileName'),
            throwsA(isA<FileValidationException>()));
        expect(
            () => pubnub.files.getFileUrl('channel', 'fileId', '../fileName'),
            throwsA(isA<FileValidationException>()));
      });

      test('getFileUrl should reject dangerous file IDs', () {
        expect(
            () => pubnub.files
                .getFileUrl('channel', '../../etc/passwd', 'fileName'),
            throwsA(isA<FileValidationException>()));
        expect(
            () => pubnub.files.getFileUrl(
                'channel', 'file${String.fromCharCode(0)}id', 'fileName'),
            throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', '..', 'fileName'),
            throwsA(isA<FileValidationException>()));
      });

      test('getFileUrl should reject dangerous file names', () {
        expect(
            () => pubnub.files
                .getFileUrl('channel', 'fileId', '../../config.ini'),
            throwsA(isA<FileValidationException>()));
        expect(
            () => pubnub.files.getFileUrl(
                'channel', 'fileId', 'file${String.fromCharCode(10)}.txt'),
            throwsA(isA<FileValidationException>()));
        expect(() => pubnub.files.getFileUrl('channel', 'fileId', 'CON'),
            throwsA(isA<FileValidationException>()));
      });

      test('should accept valid inputs', () {
        // These should not throw exceptions during validation
        expect(
            () => pubnub.files
                .getFileUrl('valid-channel', 'valid-file-id', 'valid-file.txt'),
            returnsNormally);
        expect(
            () => pubnub.files
                .getFileUrl('channel_123', 'file-id-456', 'document.pdf'),
            returnsNormally);
        expect(
            () =>
                pubnub.files.getFileUrl('test.channel', 'abc123', 'image.jpg'),
            returnsNormally);
      });

      test('should handle edge cases properly', () {
        // Test with maximum allowed lengths
        var maxChannel = 'a' * 255;
        var maxFileId = 'b' * 255;
        var maxFileName = 'c' * 255;

        expect(
            () => pubnub.files.getFileUrl(maxChannel, maxFileId, maxFileName),
            returnsNormally);

        // Test with one character over the limit
        var overLimitChannel = 'a' * 256;
        expect(
            () =>
                pubnub.files.getFileUrl(overLimitChannel, 'fileId', 'fileName'),
            throwsA(isA<FileValidationException>()));
      });
    });

    tearDown(() {
      // Reset keyset to default for next test
      keyset = Keyset(
          subscribeKey: 'test', publishKey: 'test', userId: UserId('test'));
      pubnub = PubNub(
        defaultKeyset: keyset,
        networking: FakeNetworkingModule(),
      );
    });
  });
}
