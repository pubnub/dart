part of '../app_context_test.dart';

final _setUUIDMetadataBody = '''{"name":"test","custom":{"hello":"world"}}''';

final _setChannelMetadataBody = '''{"name":"channel name","description":"channel description","custom":{"string-key":"string-value"}}''';

final _setChannelMemberMetadataBody = '''{"set":[{"uuid":{"id":"test"},"custom":{"role":"admin"}}]}''';

final _setChannelMembershipMetadataBody = '''{"set":[{"channel":{"id":"test"},"custom":{"starred":"false"}}]}''';

final _setChannelMembershipMetadataResponse = '''{"status":200,"data":[{"channel":{"id":"test","name":"channel name","description":"channel description","updated":"2025-06-22T15:07:48.219044Z","eTag":"1a24f01cbd01190c183865ec5e9c588b"},"type":null,"status":null,"updated":"2025-06-22T17:42:12.919343Z","eTag":"AfzM4PeLkOrk2wE"}],"totalCount":1,"next":"MQ"}''';

final _setChannelMemberMetadataResponse = '''{"status":200,"data":[{"uuid":{"id":"test"},"type":null,"status":null,"updated":"2025-06-22T17:14:28.972756Z","eTag":"Acr+lIO/3JX93wE"}],"totalCount":1,"next":"MQ"}''';

final _setChannelMetadataResponse = '''{
  "status": 200,
  "data": {
    "id": "s",
    "name": "channel name",
    "description": "channel description",
    "type": null,
    "status": null,
    "updated": "2025-06-22T15:07:48.219044Z",
    "eTag": "1a24f01cbd01190c183865ec5e9c588b"
  }
}
''';

final _setUUIDMetadataResponse = '''
    {"status":200,
    "data":{"id":"test",
    "name":"test",
    "externalId":null,
    "profileUrl":null,
    "email":null,
    "type":null,
    "status":null,
    "updated":"2025-06-21T12:16:59.141778Z",
    "eTag":"bf0ce352ea8c620e0cc83bcce8121f2f"}}
''';
