@TestOn('vm')
@Tags(['integration'])

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';

void main() {
  final SUBSCRIBE_KEY = Platform.environment['SDK_SUB_KEY'] ?? 'demo';
  final PUBLISH_KEY = Platform.environment['SDK_PUB_KEY'] ?? 'demo';

  late PubNub pubnub;
  late List<Subscription> activeSubscriptions;
  late String uniqueChannelPrefix;
  late List<FileInfo> uploadedFiles; // Track files for cleanup

  setUpAll(() {
    // Generate unique prefix for all test channels
    uniqueChannelPrefix =
        'dart-files-test-${DateTime.now().millisecondsSinceEpoch}';
  });

  setUp(() {
    // Create fresh PubNub instance for each test
    final userId = UserId('dart-files-test-${Random().nextInt(999999)}');
    print('Setting up test with userId: ${userId.value}');

    pubnub = PubNub(
      defaultKeyset: Keyset(
        subscribeKey: SUBSCRIBE_KEY,
        publishKey: PUBLISH_KEY,
        userId: userId,
      ),
    );
    activeSubscriptions = [];
    uploadedFiles = [];
  });

  tearDown(() async {
    print(
        'Cleaning up ${activeSubscriptions.length} subscriptions and ${uploadedFiles.length} uploaded files');

    // Cleanup subscriptions
    for (var i = 0; i < activeSubscriptions.length; i++) {
      final subscription = activeSubscriptions[i];
      try {
        if (!subscription.isCancelled) {
          print(
              'Cancelling subscription $i: channels=${subscription.channels}');
          await subscription.cancel();
        }
      } catch (e) {
        print('Error cancelling subscription $i: $e');
      }
    }
    activeSubscriptions.clear();

    try {
      await pubnub.unsubscribeAll();
    } catch (e) {
      print('Error in unsubscribeAll: $e');
    }

    // Cleanup uploaded files
    for (final fileInfo in uploadedFiles) {
      try {
        // Extract channel from file URL or use a default cleanup approach
        final url = Uri.parse(fileInfo.url!);
        final pathSegments = url.pathSegments;
        if (pathSegments.length >= 6) {
          final channel = pathSegments[5]; // Channel is at index 5 in the path
          print('Cleaning up file: ${fileInfo.name} from channel: $channel');
          await pubnub.files.deleteFile(channel, fileInfo.id, fileInfo.name);
        }
      } catch (e) {
        print('Error cleaning up file ${fileInfo.name}: $e');
        // Continue cleanup even if one file fails
      }
    }
    uploadedFiles.clear();

    // Add small delay to allow cleanup to complete
    await Future.delayed(Duration(milliseconds: 100));
  });

  group('Files Integration Tests', () {
    // Test 1: Complete file upload workflow
    test('complete_file_upload_workflow', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'upload_workflow');
      final fileName = 'test_upload_${Random().nextInt(10000)}.txt';
      final fileContent = utf8.encode('Test file content for upload workflow');
      final customMessage = 'File uploaded successfully';

      print('Testing complete upload workflow on channel: $channel');

      // Test complete sendFile workflow
      final result = await pubnub.files.sendFile(channel, fileName, fileContent,
          fileMessage: customMessage,
          storeFileMessage: true,
          customMessageType: 'file_upload_test');

      // Verify upload result
      expect(result.isError, isFalse);
      expect(result.timetoken, isNotNull);
      expect(result.timetoken, greaterThan(0));
      expect(result.fileInfo, isNotNull);
      expect(result.fileInfo!.id, isNotEmpty);
      expect(result.fileInfo!.name, equals(fileName));
      expect(result.fileInfo!.url, isNotNull);
      expect(result.fileInfo!.url, startsWith('https://'));

      print(
          'Upload successful: fileId=${result.fileInfo!.id}, timetoken=${result.timetoken}');

      // Track for cleanup
      uploadedFiles.add(result.fileInfo!);

      // Verify file URL contains expected AWS S3 parameters
      final fileUrl = Uri.parse(result.fileInfo!.url!);
      expect(fileUrl.scheme, equals('https'));
      expect(fileUrl.host, equals('ps.pndsn.com'));
      expect(fileUrl.pathSegments, contains('files'));
      expect(fileUrl.pathSegments, contains(channel));
      expect(fileUrl.pathSegments, contains(result.fileInfo!.id));
      expect(fileUrl.pathSegments, contains(fileName));
      expect(fileUrl.queryParameters.keys, contains('pnsdk'));
      expect(fileUrl.queryParameters.keys, contains('uuid'));
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 2: File download workflow
    test('file_download_workflow', () async {
      final channel = TestUtils.generateChannelName(
          uniqueChannelPrefix, 'download_workflow');
      final fileName = 'test_download_${Random().nextInt(10000)}.txt';
      final originalContent =
          utf8.encode('Test file content for download workflow');

      print('Testing file download workflow on channel: $channel');

      // First upload a file
      final uploadResult =
          await pubnub.files.sendFile(channel, fileName, originalContent);
      expect(uploadResult.isError, isFalse);
      uploadedFiles.add(uploadResult.fileInfo!);

      // Wait a bit for file to be available
      await Future.delayed(Duration(seconds: 2));

      // Download the file
      final downloadResult = await pubnub.files.downloadFile(
          channel, uploadResult.fileInfo!.id, uploadResult.fileInfo!.name);

      // Verify download result
      expect(downloadResult.fileContent, isNotNull);
      expect(downloadResult.fileContent, isA<List<int>>());
      expect(downloadResult.fileContent, equals(originalContent));

      // Verify content matches original
      final downloadedText = utf8.decode(downloadResult.fileContent);
      final originalText = utf8.decode(originalContent);
      expect(downloadedText, equals(originalText));

      print('Download successful: ${downloadedText.length} bytes downloaded');

      // Test download with incorrect file ID fails
      try {
        await pubnub.files.downloadFile(channel, 'invalid-file-id', fileName);
        fail('Expected download with invalid file ID to fail');
      } catch (e) {
        print('Expected error for invalid file ID: $e');
        expect(e, isA<PubNubException>());
      }
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 3: File listing and pagination
    test('file_listing_and_pagination', () async {
      final channel = TestUtils.generateChannelName(
          uniqueChannelPrefix, 'listing_pagination');
      final fileCount = 5;
      final uploadedFileInfos = <FileInfo>[];

      print('Testing file listing and pagination on channel: $channel');

      // Upload multiple test files
      for (var i = 0; i < fileCount; i++) {
        final fileName = 'test_list_${i}_${Random().nextInt(10000)}.txt';
        final content = utf8.encode('Content for file $i');

        final uploadResult =
            await pubnub.files.sendFile(channel, fileName, content);
        expect(uploadResult.isError, isFalse);
        uploadedFileInfos.add(uploadResult.fileInfo!);
        uploadedFiles.add(uploadResult.fileInfo!);

        // Small delay between uploads
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Wait for files to be indexed
      await Future.delayed(Duration(seconds: 3));

      // List all files
      final listResult = await pubnub.files.listFiles(channel);

      // Verify listing result
      expect(listResult.filesDetail, isNotNull);
      expect(listResult.filesDetail!.length, greaterThanOrEqualTo(fileCount));
      expect(listResult.count, greaterThanOrEqualTo(fileCount));

      // Verify file details
      for (final file in listResult.filesDetail!.take(fileCount)) {
        expect(file.id, isNotEmpty);
        expect(file.name, isNotEmpty);
        expect(file.size, greaterThan(0));
        expect(file.created, isNotNull);
        print(
            'File: ${file.name}, size: ${file.size}, created: ${file.created}');
      }

      // Test pagination with limit
      final paginatedResult = await pubnub.files.listFiles(channel, limit: 2);
      expect(paginatedResult.filesDetail!.length, lessThanOrEqualTo(2));

      if (paginatedResult.next != null) {
        // Test next page
        final nextPageResult =
            await pubnub.files.listFiles(channel, next: paginatedResult.next);
        expect(nextPageResult.filesDetail, isNotNull);
        print(
            'Pagination successful: next page has ${nextPageResult.filesDetail!.length} files');
      }
    }, timeout: Timeout(Duration(seconds: 90)));

    // Test 4: File deletion operations
    test('file_deletion_operations', () async {
      final channel = TestUtils.generateChannelName(
          uniqueChannelPrefix, 'deletion_operations');
      final fileName = 'test_delete_${Random().nextInt(10000)}.txt';
      final content = utf8.encode('Test file content for deletion');

      print('Testing file deletion operations on channel: $channel');

      // Upload a file to delete
      final uploadResult =
          await pubnub.files.sendFile(channel, fileName, content);
      expect(uploadResult.isError, isFalse);
      final fileInfo = uploadResult.fileInfo!;

      // Wait for file to be available
      await Future.delayed(Duration(seconds: 5));

      // Verify file exists in listing
      final listBeforeDelete = await pubnub.files.listFiles(channel);
      final fileExistsBeforeDelete = listBeforeDelete.filesDetail!
          .any((f) => f.id == fileInfo.id && f.name == fileInfo.name);
      expect(fileExistsBeforeDelete, isTrue);

      // Delete the file
      final deleteResult =
          await pubnub.files.deleteFile(channel, fileInfo.id, fileInfo.name);

      // Verify deletion was successful (no exception thrown)
      expect(deleteResult, isNotNull);
      print('File deleted successfully');

      // Wait for deletion to be processed
      await Future.delayed(Duration(seconds: 3));

      // Verify file no longer appears in listing
      final listAfterDelete = await pubnub.files.listFiles(channel);
      final fileExistsAfterDelete = listAfterDelete.filesDetail!
          .any((f) => f.id == fileInfo.id && f.name == fileInfo.name);
      expect(fileExistsAfterDelete, isFalse);

      // Try to download deleted file (should fail)
      try {
        await pubnub.files.downloadFile(channel, fileInfo.id, fileInfo.name);
        fail('Expected download of deleted file to fail');
      } catch (e) {
        print('Expected error for deleted file download: $e');
        expect(e, isA<PubNubException>());
      }

      // Test delete non-existent file
      try {
        await pubnub.files
            .deleteFile(channel, 'non-existent-id', 'non-existent.txt');
      } catch (e) {
        print('Expected error for non-existent file deletion: $e');
        expect(e, isA<PubNubException>());
      }
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 5: Encrypted file operations
    test('encrypted_file_operations', () async {
      final channel = TestUtils.generateChannelName(
          uniqueChannelPrefix, 'encrypted_operations');
      final fileName = 'test_encrypted_${Random().nextInt(10000)}.txt';
      final originalContent = utf8.encode('Encrypted test file content');
      final cipherKey =
          CipherKey.fromUtf8('test-encryption-key-${Random().nextInt(1000)}');

      print('Testing encrypted file operations on channel: $channel');

      // Upload encrypted file
      final uploadResult = await pubnub.files.sendFile(
          channel, fileName, originalContent,
          cipherKey: cipherKey, fileMessage: 'Encrypted file message');

      expect(uploadResult.isError, isFalse);
      uploadedFiles.add(uploadResult.fileInfo!);

      // Wait for upload to complete
      await Future.delayed(Duration(seconds: 2));

      // Download and decrypt file
      final downloadResult = await pubnub.files.downloadFile(
          channel, uploadResult.fileInfo!.id, uploadResult.fileInfo!.name,
          cipherKey: cipherKey);

      // Verify decrypted content matches original
      expect(downloadResult.fileContent, equals(originalContent));

      final decryptedText = utf8.decode(downloadResult.fileContent);
      final originalText = utf8.decode(originalContent);
      expect(decryptedText, equals(originalText));

      print('Encryption/decryption successful: ${decryptedText.length} bytes');

      // Test that different cipher key fails to decrypt properly
      try {
        final wrongKey = CipherKey.fromUtf8('wrong-encryption-key');
        final failedDownload = await pubnub.files.downloadFile(
            channel, uploadResult.fileInfo!.id, uploadResult.fileInfo!.name,
            cipherKey: wrongKey);

        // The content should be different (corrupted) when using wrong key
        expect(failedDownload.fileContent, isNot(equals(originalContent)));
        print('Different cipher key produces different result as expected');
      } catch (e) {
        // This is also acceptable - decryption with wrong key may throw
        print('Wrong cipher key caused error as expected: $e');
      }

      // Test encryption utility methods
      final encryptedBytes =
          pubnub.files.encryptFile(originalContent, cipherKey: cipherKey);
      expect(encryptedBytes, isNot(equals(originalContent)));

      final decryptedBytes =
          pubnub.files.decryptFile(encryptedBytes, cipherKey: cipherKey);
      expect(decryptedBytes, equals(originalContent));
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 6: Large file handling
    test('large_file_handling', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'large_file');
      final fileName = 'test_large_${Random().nextInt(10000)}.bin';

      // Generate large file (1MB)
      final largeContent =
          TestUtils.generateLargeFileContent(1024 * 1024); // 1MB

      print(
          'Testing large file handling on channel: $channel (${largeContent.length} bytes)');

      // Upload large file
      final uploadResult = await pubnub.files.sendFile(
          channel, fileName, largeContent,
          fileMessage: 'Large file test');

      expect(uploadResult.isError, isFalse);
      uploadedFiles.add(uploadResult.fileInfo!);

      print(
          'Large file uploaded successfully: fileId=${uploadResult.fileInfo!.id}');

      // Wait for upload to complete
      await Future.delayed(Duration(seconds: 5));

      // Download large file
      final downloadResult = await pubnub.files.downloadFile(
          channel, uploadResult.fileInfo!.id, uploadResult.fileInfo!.name);

      // Verify content integrity
      expect(downloadResult.fileContent.length, equals(largeContent.length));
      expect(downloadResult.fileContent, equals(largeContent));

      print(
          'Large file download successful: ${downloadResult.fileContent.length} bytes');

      // Verify file appears in listing with correct size
      final listResult = await pubnub.files.listFiles(channel);
      final uploadedFile = listResult.filesDetail!.firstWhere(
          (f) => f.id == uploadResult.fileInfo!.id,
          orElse: () => throw StateError('Uploaded file not found in listing'));

      expect(uploadedFile.size, equals(largeContent.length));
    },
        timeout:
            Timeout(Duration(seconds: 180))); // Longer timeout for large files

    // Test 7: File message publish workflow
    test('file_message_publish_workflow', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'file_message');
      final fileName = 'test_message_${Random().nextInt(10000)}.txt';
      final content = utf8.encode('File content for message test');
      final customMessage = {'type': 'test', 'data': 'Custom file message'};

      print('Testing file message publish workflow on channel: $channel');

      // Create subscription to receive file message
      final subscription = pubnub.subscribe(channels: {channel});
      activeSubscriptions.add(subscription);

      final messageQueue = StreamQueue(subscription.messages);
      await subscription.whenStarts;

      // Upload file with custom message
      final uploadResult =
          await pubnub.files.sendFile(channel, fileName, content,
              fileMessage: customMessage,
              storeFileMessage: true,
              fileMessageTtl: 3600, // 1 hour
              customMessageType: 'file_notification');

      expect(uploadResult.isError, isFalse);
      uploadedFiles.add(uploadResult.fileInfo!);

      // Wait for file message
      final envelope = await TestUtils.waitForMessage(messageQueue,
          description: 'file message');

      // Verify file message structure
      expect(envelope.payload, isNotNull);
      expect(envelope.channel, equals(channel));
      expect(envelope.publishedAt, isNotNull);

      final payload = envelope.payload;
      if (payload is Map) {
        expect(payload['message'], equals(customMessage));
        expect(payload['file'], isNotNull);

        final fileInfo = payload['file'];
        expect(fileInfo['id'], equals(uploadResult.fileInfo!.id));
        expect(fileInfo['name'], equals(fileName));
      }

      print('File message received successfully');

      // Test standalone file message publishing
      final fileInfo =
          FileInfo('test-id', 'test-file.txt', 'https://example.com/test');
      final fileMessage = FileMessage(fileInfo, message: 'Standalone message');

      final publishResult = await pubnub.files.publishFileMessage(
          channel, fileMessage,
          storeMessage: true, meta: {'test': true});

      expect(publishResult.isError, isFalse);
      expect(publishResult.timetoken, isNotNull);

      await TestUtils.cancelMessageQueue(messageQueue);
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 8: Multi-keyset operations
    test('multi_keyset_operations', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'multi_keyset');
      final fileName = 'test_keyset_${Random().nextInt(10000)}.txt';
      final content = utf8.encode('Multi-keyset test content');

      print('Testing multi-keyset operations on channel: $channel');

      // Create second PubNub instance with different userId
      final secondUserId =
          UserId('dart-files-test-2-${Random().nextInt(999999)}');
      final secondPubNub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: SUBSCRIBE_KEY,
          publishKey: PUBLISH_KEY,
          userId: secondUserId,
        ),
      );

      // Upload file with first keyset
      final uploadResult =
          await pubnub.files.sendFile(channel, fileName, content);
      expect(uploadResult.isError, isFalse);
      uploadedFiles.add(uploadResult.fileInfo!);

      // Wait for upload
      await Future.delayed(Duration(seconds: 2));

      // Try to access with second keyset (same subscribe key)
      final downloadResult = await secondPubNub.files.downloadFile(
          channel, uploadResult.fileInfo!.id, uploadResult.fileInfo!.name);

      // Should be able to download with same subscribe key
      expect(downloadResult.fileContent, equals(content));

      // List files with second keyset
      final listResult = await secondPubNub.files.listFiles(channel);
      final fileExists =
          listResult.filesDetail!.any((f) => f.id == uploadResult.fileInfo!.id);
      expect(fileExists, isTrue);

      // Test with auth key
      final authKeyset = Keyset(
        subscribeKey: SUBSCRIBE_KEY,
        publishKey: PUBLISH_KEY,
        userId: UserId('auth-test'),
        authKey: 'test-auth-key',
      );

      final authPubNub = PubNub(defaultKeyset: authKeyset);

      // Get file URL with auth key
      final fileUrl = authPubNub.files.getFileUrl(
          channel, uploadResult.fileInfo!.id, uploadResult.fileInfo!.name);

      expect(fileUrl.queryParameters['auth'], equals('test-auth-key'));

      // Cleanup second PubNub
      await secondPubNub.unsubscribeAll();
      await authPubNub.unsubscribeAll();
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 9: Error handling integration
    test('error_handling_integration', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'error_handling');

      print('Testing error handling integration on channel: $channel');

      // Test invalid file name
      try {
        await pubnub.files.sendFile(channel, '../../../etc/passwd', [1, 2, 3]);
        fail('Expected file validation to fail');
      } catch (e) {
        expect(e, isA<FileValidationException>());
        print('File validation error as expected: $e');
      }

      // Test invalid channel name
      try {
        await pubnub.files.sendFile('', 'test.txt', [1, 2, 3]);
        fail('Expected channel validation to fail');
      } catch (e) {
        expect(e, isA<FileValidationException>());
        print('Channel validation error as expected: $e');
      }

      // Test empty file content
      try {
        await pubnub.files.sendFile(channel, 'empty.txt', []);
        // This might succeed or fail depending on implementation
        print('Empty file upload attempted');
      } catch (e) {
        print('Empty file error: $e');
      }

      // Test invalid PubNub configuration
      final invalidPubNub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'invalid-subscribe-key',
          publishKey: 'invalid-publish-key',
          userId: UserId('error-test'),
        ),
      );

      try {
        await invalidPubNub.files.sendFile(channel, 'test.txt', [1, 2, 3]);
        fail('Expected invalid keyset to fail');
      } catch (e) {
        expect(e, isA<PubNubException>());
        print('Invalid keyset error as expected: $e');
      }

      // Test download non-existent file
      try {
        await pubnub.files.downloadFile(channel, 'non-existent-id', 'test.txt');
        fail('Expected non-existent file download to fail');
      } catch (e) {
        expect(e, isA<PubNubException>());
        print('Non-existent file download error as expected: $e');
      }

      // Test list files on non-existent channel
      final listResult = await pubnub.files
          .listFiles('non-existent-channel-${Random().nextInt(100000)}');
      expect(listResult.filesDetail ?? [], isEmpty);
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 10: File message retry logic
    test('file_message_retry_logic', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'retry_logic');
      final fileName = 'test_retry_${Random().nextInt(10000)}.txt';
      final content = utf8.encode('Retry test content');

      print('Testing file message retry logic on channel: $channel');

      // Create PubNub with limited retry count
      final retryKeyset = Keyset(
        subscribeKey: SUBSCRIBE_KEY,
        publishKey: PUBLISH_KEY,
        userId: UserId('retry-test'),
      );
      retryKeyset.fileMessagePublishRetryLimit = 2;

      final retryPubNub = PubNub(
        defaultKeyset: retryKeyset,
      );

      // Upload file (this tests the retry logic internally)
      final uploadResult = await retryPubNub.files.sendFile(
          channel, fileName, content,
          fileMessage: 'Retry test message');

      // Even if publish fails, file upload should succeed
      expect(uploadResult.fileInfo, isNotNull);
      expect(uploadResult.fileInfo!.id, isNotEmpty);
      expect(uploadResult.fileInfo!.name, equals(fileName));

      uploadedFiles.add(uploadResult.fileInfo!);

      // If publish succeeded
      if (!uploadResult.isError!) {
        expect(uploadResult.timetoken, greaterThan(0));
        print('File upload and message publish succeeded');
      } else {
        // If publish failed after retries, file should still be uploaded
        print(
            'File uploaded but message publish failed as expected for retry test');
        expect(uploadResult.description, contains('publish failed'));

        // Manual retry of file message publishing
        final fileMessage = FileMessage(uploadResult.fileInfo!,
            message: 'Manual retry message');
        final retryResult =
            await retryPubNub.files.publishFileMessage(channel, fileMessage);

        // This should succeed since file is already uploaded
        expect(retryResult.isError, isFalse);
        expect(retryResult.timetoken, greaterThan(0));
        print('Manual file message publish retry succeeded');
      }

      await retryPubNub.unsubscribeAll();
    }, timeout: Timeout(Duration(seconds: 60)));

    // Test 11: Concurrent file operations
    test('concurrent_file_operations', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'concurrent_ops');
      final concurrentCount = 3;

      print('Testing concurrent file operations on channel: $channel');

      // Prepare multiple files for concurrent upload
      final uploadTasks = <Future<PublishFileMessageResult>>[];
      final fileContents = <List<int>>[];

      for (var i = 0; i < concurrentCount; i++) {
        final fileName = 'concurrent_${i}_${Random().nextInt(10000)}.txt';
        final content = utf8.encode('Concurrent file content $i');
        fileContents.add(content);

        uploadTasks.add(pubnub.files.sendFile(channel, fileName, content,
            fileMessage: 'Concurrent upload $i'));
      }

      // Execute concurrent uploads
      final uploadResults = await Future.wait(uploadTasks);

      // Verify all uploads succeeded
      for (var i = 0; i < uploadResults.length; i++) {
        final result = uploadResults[i];
        expect(result.isError, isFalse);
        expect(result.fileInfo, isNotNull);
        uploadedFiles.add(result.fileInfo!);
        print('Concurrent upload $i succeeded: ${result.fileInfo!.id}');
      }

      // Wait for uploads to complete
      await Future.delayed(Duration(seconds: 3));

      // Prepare concurrent downloads
      final downloadTasks = <Future<DownloadFileResult>>[];

      for (var i = 0; i < uploadResults.length; i++) {
        final fileInfo = uploadResults[i].fileInfo!;
        downloadTasks.add(
            pubnub.files.downloadFile(channel, fileInfo.id, fileInfo.name));
      }

      // Execute concurrent downloads
      final downloadResults = await Future.wait(downloadTasks);

      // Verify all downloads succeeded and content matches
      for (var i = 0; i < downloadResults.length; i++) {
        final downloadResult = downloadResults[i];
        expect(downloadResult.fileContent, equals(fileContents[i]));
        print(
            'Concurrent download $i succeeded: ${downloadResult.fileContent.length} bytes');
      }

      // Test concurrent file operations don't interfere with each other
      expect(downloadResults.length, equals(concurrentCount));

      // Verify data integrity - each file should contain its own unique content
      for (var i = 0; i < downloadResults.length; i++) {
        final downloadedText = utf8.decode(downloadResults[i].fileContent);
        expect(downloadedText, contains('content $i'));
      }
    }, timeout: Timeout(Duration(seconds: 120)));

    // Test 12: File type validation
    test('file_type_handling', () async {
      final channel =
          TestUtils.generateChannelName(uniqueChannelPrefix, 'file_types');

      print('Testing different file types on channel: $channel');

      final testFiles = <String, List<int>>{
        'text_file.txt': utf8.encode('This is a plain text file'),
        'json_file.json': utf8.encode('{"key": "value", "number": 42}'),
        'binary_file.bin': List.generate(256, (i) => i % 256), // Binary data
        'image_file.jpg':
            TestUtils.generateBinaryContent(1024), // Mock image data
        'no_extension': utf8.encode('File without extension'),
        'unusual.xyz': utf8.encode('File with unusual extension'),
      };

      final uploadResults = <String, PublishFileMessageResult>{};

      // Upload all file types
      for (final entry in testFiles.entries) {
        final fileName = entry.key;
        final content = entry.value;

        print('Uploading file type: $fileName (${content.length} bytes)');

        final result = await pubnub.files.sendFile(channel, fileName, content,
            fileMessage: 'File type test: $fileName');

        expect(result.isError, isFalse);
        expect(result.fileInfo, isNotNull);

        uploadResults[fileName] = result;
        uploadedFiles.add(result.fileInfo!);

        // Small delay between uploads
        await Future.delayed(Duration(milliseconds: 200));
      }

      // Wait for all uploads to complete
      await Future.delayed(Duration(seconds: 3));

      // Download and verify each file type
      for (final entry in testFiles.entries) {
        final fileName = entry.key;
        final originalContent = entry.value;
        final uploadResult = uploadResults[fileName]!;

        print('Downloading and verifying file type: $fileName');

        final downloadResult = await pubnub.files.downloadFile(
            channel, uploadResult.fileInfo!.id, uploadResult.fileInfo!.name);

        // Verify content integrity
        expect(downloadResult.fileContent, equals(originalContent));

        // For text files, also verify string content
        if (fileName.endsWith('.txt') ||
            fileName.endsWith('.json') ||
            fileName == 'no_extension') {
          final downloadedText = utf8.decode(downloadResult.fileContent);
          final originalText = utf8.decode(originalContent);
          expect(downloadedText, equals(originalText));
        }
      }

      // Verify all files appear in listing
      final listResult = await pubnub.files.listFiles(channel);
      expect(listResult.filesDetail!.length,
          greaterThanOrEqualTo(testFiles.length));

      for (final fileName in testFiles.keys) {
        final fileExists =
            listResult.filesDetail!.any((f) => f.name == fileName);
        expect(fileExists, isTrue,
            reason: 'File $fileName should exist in listing');
      }
    }, timeout: Timeout(Duration(seconds: 120)));
  }); // End of Files Integration Tests group
}

/// Utility functions for file integration tests
class TestUtils {
  /// Waits for a message with timeout and proper error handling
  static Future<Envelope> waitForMessage(
    StreamQueue<Envelope> messageQueue, {
    Duration timeout = const Duration(seconds: 20),
    String? description,
  }) async {
    try {
      final envelope = await messageQueue.next.timeout(timeout);
      print(
          'Received message${description != null ? ' ($description)' : ''}: ${envelope.payload}');
      return envelope;
    } on TimeoutException {
      final desc = description ?? 'message';
      throw TimeoutException(
          'Timeout waiting for $desc after ${timeout.inSeconds}s', timeout);
    } catch (e) {
      final desc = description ?? 'message';
      print('Error waiting for $desc: $e');
      rethrow;
    }
  }

  /// Safely cancels a message queue with error handling
  static Future<void> cancelMessageQueue(
      StreamQueue<Envelope> messageQueue) async {
    try {
      await messageQueue.cancel();
    } catch (e) {
      print('Error cancelling message queue: $e');
      // Don't rethrow - cleanup should continue
    }
  }

  /// Generates a unique channel name for testing
  static String generateChannelName(String uniquePrefix, String testName) {
    return '${uniquePrefix}_${testName}_${Random().nextInt(100000)}_${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  /// Generates large file content for testing
  static List<int> generateLargeFileContent(int sizeBytes) {
    final random = Random();
    final content = <int>[];

    // Generate repetitive but varied content
    final pattern =
        'LARGE FILE TEST CONTENT ${DateTime.now().millisecondsSinceEpoch} ';
    final patternBytes = utf8.encode(pattern);

    while (content.length < sizeBytes) {
      content.addAll(patternBytes);

      // Add some random bytes for variety
      if (content.length < sizeBytes) {
        content.add(random.nextInt(256));
      }
    }

    // Trim to exact size
    return content.take(sizeBytes).toList();
  }

  /// Generates binary content for testing
  static List<int> generateBinaryContent(int sizeBytes) {
    final random = Random();
    return List.generate(sizeBytes, (_) => random.nextInt(256));
  }
}
