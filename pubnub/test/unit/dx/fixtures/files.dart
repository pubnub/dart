part of '../file_test.dart';

final _getFileUrl =
    'https://ps.pndsn.com/v1/files/test/channels/channel/files/fileId/fileName?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test';

// Mock responses for multi-step file upload flow (JSON strings)
final _generateUploadUrlResponseJson = '''
{
  "data": {
    "id": "test-file-id-123",
    "name": "test-file.txt"
  },
  "file_upload_request": {
    "url": "https://s3.example.com/upload",
    "form_fields": [
      {"key": "key", "value": "files/test-file-id-123/test-file.txt"},
      {"key": "bucket", "value": "pubnub-files"},
      {"key": "X-Amz-Algorithm", "value": "AWS4-HMAC-SHA256"},
      {"key": "X-Amz-Credential", "value": "test-credentials"},
      {"key": "X-Amz-Date", "value": "20240101T000000Z"},
      {"key": "X-Amz-Signature", "value": "test-signature"},
      {"key": "policy", "value": "test-policy"}
    ]
  }
}
''';

final _generateUploadUrlResponse = {
  "data": {"id": "test-file-id-123", "name": "test-file.txt"},
  "file_upload_request": {
    "url": "https://s3.example.com/upload",
    "form_fields": [
      {"key": "key", "value": "files/test-file-id-123/test-file.txt"},
      {"key": "bucket", "value": "pubnub-files"},
      {"key": "X-Amz-Algorithm", "value": "AWS4-HMAC-SHA256"},
      {"key": "X-Amz-Credential", "value": "test-credentials"},
      {"key": "X-Amz-Date", "value": "20240101T000000Z"},
      {"key": "X-Amz-Signature", "value": "test-signature"},
      {"key": "policy", "value": "test-policy"}
    ]
  }
};

final _fileUploadSuccessResponse = '';

final _publishFileMessageSuccessResponseJson = '[1, "Sent", "15566918187234"]';
final _publishFileMessageFailureResponseJson =
    '[0, "Forbidden", "15566918187234"]';

final _publishFileMessageSuccessResponse = [1, "Sent", "15566918187234"];
final _publishFileMessageFailureResponse = [0, "Forbidden", "15566918187234"];

// List files responses (JSON strings)
final _listFilesResponseJson = '''
{
  "data": [
    {
      "name": "test-file-1.txt",
      "id": "file-id-1", 
      "size": 1024,
      "created": "2024-01-01T10:00:00.000Z"
    },
    {
      "name": "test-file-2.jpg",
      "id": "file-id-2",
      "size": 2048,
      "created": "2024-01-01T11:00:00.000Z"
    }
  ],
  "count": 2,
  "next": "next-page-token"
}
''';

final _listFilesEmptyResponseJson = '''
{
  "data": [],
  "count": 0,
  "next": null
}
''';

final _listFilesPaginationResponseJson = '''
{
  "data": [
    {
      "name": "page2-file.txt",
      "id": "page2-file-id",
      "size": 512,
      "created": "2024-01-01T12:00:00.000Z"
    }
  ],
  "count": 1,
  "next": null
}
''';

// Object versions for direct use
final _listFilesResponse = {
  "data": [
    {
      "name": "test-file-1.txt",
      "id": "file-id-1",
      "size": 1024,
      "created": "2024-01-01T10:00:00.000Z"
    },
    {
      "name": "test-file-2.jpg",
      "id": "file-id-2",
      "size": 2048,
      "created": "2024-01-01T11:00:00.000Z"
    }
  ],
  "count": 2,
  "next": "next-page-token"
};

final _listFilesEmptyResponse = {"data": [], "count": 0, "next": null};

final _listFilesPaginationResponse = {
  "data": [
    {
      "name": "page2-file.txt",
      "id": "page2-file-id",
      "size": 512,
      "created": "2024-01-01T12:00:00.000Z"
    }
  ],
  "count": 1,
  "next": null
};

// Download file mock content
final _downloadFileContent = [
  72,
  101,
  108,
  108,
  111,
  32,
  87,
  111,
  114,
  108,
  100
]; // "Hello World" as bytes

final _encryptedFileContent = [
  145,
  23,
  67,
  89,
  123,
  45,
  78,
  90,
  234,
  156,
  78
]; // Mock encrypted bytes

// Delete file success response
final _deleteFileSuccessResponseJson = '{}';
final _deleteFileSuccessResponse = {};
