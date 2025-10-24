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

// XML Error Response Fixtures for AWS S3 Errors
final _entityTooLargeXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>EntityTooLarge</Code>
  <Message>Your proposed upload exceeds the maximum allowed size</Message>
  <ProposedSize>5244154</ProposedSize>
  <MaxSizeAllowed>5242880</MaxSizeAllowed>
  <RequestId>P570ENA92X4PR7DF</RequestId>
  <HostId>zYdZeAd/hIiBlNKrImKG9G3UcPZkDmlRiKr4izWWNkzkhY/cQRa6KXpbAKOOW4ut6d/HMXKEbw8=</HostId>
</Error>
''';

final _noSuchKeyXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>NoSuchKey</Code>
  <Message>The specified key does not exist.</Message>
  <Key>files/nonexistent-file-id/nonexistent-file.txt</Key>
  <RequestId>4442587FB7D0A2F9</RequestId>
  <HostId>9+qQfpZ9cGBFuPiXJKiKk9dAqNuUKiXiCqVf9QKdGJZLjQJNvGRXVGRJD3Qx3QYb</HostId>
</Error>
''';

final _accessDeniedXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>AccessDenied</Code>
  <Message>Access Denied</Message>
  <RequestId>656c76696e6727732072657175657374</RequestId>
  <HostId>Uuag1LuByRx9e6j5Onimru9pO4ZVKnJ2Qz7/C1NPcfTWAtRPfTaOFg==</HostId>
</Error>
''';

final _signatureDoesNotMatchXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>SignatureDoesNotMatch</Code>
  <Message>The request signature we calculated does not match the signature you provided.</Message>
  <AWSAccessKeyId>AKIAIOSFODNN7EXAMPLE</AWSAccessKeyId>
  <StringToSign>AWS4-HMAC-SHA256...</StringToSign>
  <RequestId>4442587FB7D0A2F9</RequestId>
  <HostId>9+qQfpZ9cGBFuPiXJKiKk9dAqNuUKiXiCqVf9QKdGJZLjQJNvGRXVGRJD3Qx3QYb</HostId>
</Error>
''';

final _internalErrorXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>InternalError</Code>
  <Message>We encountered an internal error. Please try again.</Message>
  <RequestId>INTERNAL123</RequestId>
  <HostId>example-host-id</HostId>
</Error>
''';

final _invalidBucketNameXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>InvalidBucketName</Code>
  <Message>The specified bucket is not valid</Message>
  <BucketName>invalid-bucket</BucketName>
  <RequestId>LIST123</RequestId>
</Error>
''';

final _deleteFileNoSuchKeyXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>NoSuchKey</Code>
  <Message>The specified key does not exist.</Message>
  <Key>files/delete-file-id/delete-file.txt</Key>
  <RequestId>DELETE123</RequestId>
</Error>
''';

final _specialCharactersXmlError = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>InvalidArgument</Code>
  <Message>Invalid argument: &lt;test&gt; &amp; "quotes" &#39;single&#39;</Message>
  <ArgumentName>file-name</ArgumentName>
  <ArgumentValue>test&lt;&gt;&amp;"'file.txt</ArgumentValue>
  <RequestId>SPECIAL123</RequestId>
</Error>
''';
