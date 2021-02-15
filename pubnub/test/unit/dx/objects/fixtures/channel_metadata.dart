part of '../channel_metadata_test.dart';

final _getAllMetadataSuccessResponse = '''{
  "status": 200,
  "data": [
    {
      "id": "my-channel",
      "name": "My channel",
      "description": "A channel that is mine",
      "custom": null,
      "updated": "2019-02-20T23:11:20.893755",
      "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="
    },
    {
      "id": "main",
      "name": "Main channel",
      "description": "The main channel",
      "custom": {
        "public": true,
        "motd": "Always check your spelling!"
      },
      "updated": "2019-02-20T23:11:20.893755",
      "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="
    }
  ],
  "totalCount": 9,
  "next": "MUIwQTAwMUItQkRBRC00NDkyLTgyMEMtODg2OUU1N0REMTNBCg==",
  "prev": "M0FFODRENzMtNjY2Qy00RUExLTk4QzktNkY1Q0I2MUJFNDRCCg=="
}
''';

final _getMetadataSuccessResponse = '''{
  "status": 200,
  "data": {
    "id": "my-channel",
    "name": "My channel",
    "description": "A channel that is mine",
    "updated": "2019-02-20T23:11:20.893755",
    "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="
  }
}
''';

final _setChannelMetadataBody =
    '{"name":"My channel","description":"A channel that is mine","custom":null}';

final _setChannelMetadataSuccessResponse = '''{
  "status": 200,
  "data": {
    "id": "my-channel",
    "name": "My channel",
    "description": "A channel that is mine",
    "updated": "2019-02-20T23:11:20.893755",
    "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="
  }
}
''';

final _removeMetadataSuccessResponse = '''{
  "status": 0,
  "data": {}
}
''';
