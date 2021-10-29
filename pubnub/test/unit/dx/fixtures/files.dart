part of '../file_test.dart';

final _listFilesSuccessResponse = '''{
  "status": 200,
  "data": [
    {
      "name": "test_file.jpg",
      "id": "5a3eb38c-483a-4b25-ac01-c4e20deba6d6",
      "size": 203923,
      "created": "2020-04-22T22:48:31Z"
    }
  ],
  "next": "lnlngwonowgong",
  "count": 100
}''';
final _publishFileMessageSuccessResponse = '[1, "Sent", "1"]';

final _publishFileMessageFailureResponse = '[0, "Invalid subscribe key", "1"]';

final _deleteFileResponse = '''
{
  "status": 200
}''';

final _generateFileUploadUrlResponse = '''
{
  "status": 200,
  "data": {
    "id": "5a3eb38c-483a-4b25-ac01-c4e20deba6d6",
    "name": "cat_file.jpg"
  },
  "file_upload_request": {
    "url": "https://pubnub-test-config.s3.amazonaws.com",
    "method": "POST",
    "expiration_date": "2020-04-03T22:44:47Z",
    "form_fields": [
      {
        "key": "tagging",
        "value": "<Tagging><TagSet><Tag><Key>ObjectTTL</Key><Value>1000</Value></Tag></TagSet></Tagging>"
      },
      {
        "key": "key",
        "value": "file-upload/5a3eb38c-483a-4b25-ac01-c4e20deba6d6/test_image.jpg"
      },
      {
        "key": "Content-Type",
        "value": "binary/octet-stream"
      },
      {
        "key": "X-Amz-Credential",
        "value": "xxx/20200403/us-west-2/s3/aws4_request"
      },
      {
        "key": "X-Amz-Security-Token",
        "value": "lgnwegn2mg202j4g0g2mg04g02gj2"
      },
      {
        "key": "X-Amz-Algorithm",
        "value": "AWS4-HMAC-SHA256"
      },
      {
        "key": "X-Amz-Date",
        "value": "20200403T212950Z"
      },
      {
        "key": "Policy",
        "value": "CnsgImV4cGlyYXRpb24iOiAiMjAyMC0wNC0wM1QyMToy..."
      },
      {
        "key": "X-Amz-Signature",
        "value": "1fbaad6738c6cd4c7eec2afe4cb2553a1e9cd2be690fdc2ecdc6e26f60a3781a"
      }
    ]
  }
}
''';

final _sendFileResponse = '''
{
  "tagging": "<Tagging><TagSet><Tag><Key>ObjectTTL</Key><Value>1000</Value></Tag></TagSet></Tagging>",
  "key": "file-upload/5a3eb38c-483a-4b25-ac01-c4e20deba6d6/test_image.jpg",
  "Content-Type": "binary/octet-stream",
  "X-Amz-Credential": "xxx/20200403/us-west-2/s3/aws4_request",
  "X-Amz-Security-Token": "lgnwegn2mg202j4g0g2mg04g02gj2",
  "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
  "X-Amz-Date": "20200403T212950Z",
  "Policy": "CnsgImV4cGlyYXRpb24iOiAiMjAyMC0wNC0wM1QyMToy...",
  "X-Amz-Signature": "1fbaad6738c6cd4c7eec2afe4cb2553a1e9cd2be690fdc2ecdc6e26f60a3781a",
  "file": [0, 1, 2, 3]
}
''';

final _publishFileMessageUrl1 =
    'v1/files/publish-file/test/test/0/channel/0/%7B%22message%22:%22msg%22,%22file%22:%7B%22id%22:%22some%22,%22name%22:%22cat_file.jpg%22%7D%7D?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test';

final _publishFileMessageUrlEncryption =
    'v1/files/publish-file/test/test/0/channel/0/%22X3LuZh36Z3vi4HFJSxdqD7XN%2FTsyUiPBmDfVaRipvaYs8wQE6OOloLTjGSTnZXIb0knFDIr8jPniWrnUYtdoTQ==%22?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test';

final _publishFileMessageUrl2 =
    'v1/files/publish-file/test/test/0/channel/0/%7B%22message%22:%22msg%22,%22file%22:%7B%22id%22:%225a3eb38c-483a-4b25-ac01-c4e20deba6d6%22,%22name%22:%22cat_file.jpg%22,%22url%22:%22https:%2F%2Fps.pndsn.com%2Fv1%2Ffiles%2Ftest%2Fchannels%2Fchannel%2Ffiles%2F5a3eb38c-483a-4b25-ac01-c4e20deba6d6%2Fcat_file.jpg%3Fpnsdk=PubNub-Dart%252F1.4.2%22%7D%7D?pnsdk=PubNub-Dart%2F${PubNub.version}';

final _generateFileUploadUrl =
    'v1/files/test/channels/channel/generate-upload-url?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test';

final _downloadFileUrl =
    'https://ps.pndsn.com/v1/files/test/channels/channel/files/5a3eb38c-483a-4b25-ac01-c4e20deba6d6/cat_file.jpg?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test';

final _getFileUrl =
    'https://ps.pndsn.com/v1/files/test/channels/channel/files/fileId/fileName?pnsdk=PubNub-Dart%2F${PubNub.version}';
