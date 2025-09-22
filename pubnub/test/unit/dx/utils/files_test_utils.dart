import 'dart:typed_data';
import 'dart:convert';
import '../../net/custom_fake_net.dart' as enhanced;
import 'package:pubnub/pubnub.dart';

/// Enhanced test utilities for Files API
class FilesTestUtils {
  /// Create properly encrypted test data
  static EncryptedTestData createEncryptedTestData(String plainText,
      [String key = 'test-key']) {
    final plainBytes = utf8.encode(plainText);

    // Create mock encrypted data (simulated AES-CBC with IV)
    final iv = Uint8List.fromList(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
    final mockEncrypted = Uint8List.fromList([
      ...iv, // 16 bytes IV
      ...plainBytes.map((b) => b ^ 0x55), // Simple XOR "encryption" for testing
    ]);

    return EncryptedTestData(
      plainText: plainText,
      plainBytes: plainBytes,
      encryptedBytes: mockEncrypted,
      key: key,
      iv: iv,
    );
  }

  /// Set up multi-step file upload mocks
  static void setupSendFileMocks({
    required String channel,
    required String fileName,
    String fileId = 'test-file-id-123',
    String uploadUrl = 'https://s3.example.com/upload',
    bool uploadShouldSucceed = true,
    bool publishShouldSucceed = true,
    int publishRetries = 0,
  }) {
    // Step 1: Generate upload URL
    enhanced
        .whenExternal(
            method: 'POST',
            path:
                '/v1/files/test/channels/$channel/generate-upload-url?uuid=test',
            body: '{"name":"$fileName"}')
        .then(status: 200, body: '''
      {
        "data": {
          "id": "$fileId",
          "name": "$fileName"
        },
        "file_upload_request": {
          "url": "$uploadUrl",
          "form_fields": [
            {"key": "key", "value": "files/$fileId/$fileName"},
            {"key": "bucket", "value": "pubnub-files"}
          ]
        }
      }
      ''');

    // Step 2: File upload to external service
    enhanced
        .whenExternal(method: 'POST', path: uploadUrl, body: 'FILE_UPLOAD_DATA')
        .then(
            status: uploadShouldSucceed ? 200 : 500,
            body: uploadShouldSucceed ? '' : 'Upload failed');

    // Step 3: Publish file message (with retries if needed)
    final messagePath =
        '/v1/files/publish-file/test/test/0/$channel/0/{"message":null,"file":{"id":"$fileId","name":"$fileName"}}?uuid=test';

    // Add failure mocks for retries
    for (int i = 0; i < publishRetries; i++) {
      enhanced
          .whenExternal(method: 'GET', path: messagePath)
          .then(status: 500, body: '[0, "Server Error", "15566918187234"]');
    }

    // Final publish attempt
    enhanced.whenExternal(method: 'GET', path: messagePath).then(
        status: publishShouldSucceed ? 200 : 500,
        body: publishShouldSucceed
            ? '[1, "Sent", "15566918187234"]'
            : '[0, "Failed", "15566918187234"]');
  }

  /// Set up download file mock with proper encryption
  static void setupDownloadFileMock({
    required String channel,
    required String fileId,
    required String fileName,
    List<int>? fileContent,
    bool encrypted = false,
    int statusCode = 200,
  }) {
    final content = fileContent ?? utf8.encode('Test file content');

    enhanced
        .whenExternal(
            method: 'GET',
            path:
                '/v1/files/test/channels/$channel/files/$fileId/$fileName?uuid=test')
        .then(status: statusCode, body: content);
  }

  /// Create test file content of various types
  static List<int> createTestFileContent(FileContentType type,
      {int size = 1024}) {
    switch (type) {
      case FileContentType.text:
        return utf8.encode('Test file content with some text data');
      case FileContentType.binary:
        return List.generate(size, (i) => i % 256); // Binary pattern
      case FileContentType.empty:
        return [];
      case FileContentType.large:
        return List.filled(size, 65); // 'A' repeated
      case FileContentType.image:
        // PNG file signature + minimal data
        return [137, 80, 78, 71, 13, 10, 26, 10, ...List.filled(size - 8, 0)];
    }
  }
}

/// Types of test file content
enum FileContentType {
  text,
  binary,
  empty,
  large,
  image,
}

/// Container for encrypted test data
class EncryptedTestData {
  final String plainText;
  final List<int> plainBytes;
  final List<int> encryptedBytes;
  final String key;
  final List<int> iv;

  const EncryptedTestData({
    required this.plainText,
    required this.plainBytes,
    required this.encryptedBytes,
    required this.key,
    required this.iv,
  });
}

/// Mock crypto module for testing encryption scenarios
class MockCryptoModule {
  final Map<String, List<int>> _encryptedData = {};

  List<int> encrypt(List<int> data) {
    final key = 'default';
    final encrypted = data.map((b) => b ^ 0x55).toList(); // Simple XOR
    _encryptedData[key] = encrypted;
    return encrypted;
  }

  List<int> decrypt(List<int> data) {
    return data.map((b) => b ^ 0x55).toList(); // Reverse XOR
  }

  List<int> encryptFileData(CipherKey key, List<int> data) {
    final keyStr = key.toString();
    final encrypted = data.map((b) => b ^ 0x55).toList(); // Simple XOR
    _encryptedData[keyStr] = encrypted;
    return encrypted;
  }

  List<int> decryptFileData(CipherKey key, List<int> data) {
    return data.map((b) => b ^ 0x55).toList(); // Reverse XOR
  }
}
