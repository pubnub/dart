part of '../uuid_metadata_test.dart';

final _getAllMetadataSuccessResponse = '''{
  "status": 200,
  "data": [
    {
      "id": "uuid-1",
      "name": "John Doe",
      "externalId": null,
      "profileUrl": null,
      "email": "jack@twitter.com",
      "custom": null,
      "updated": "2019-02-20T23:11:20.893755",
      "eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="
    },
    {
      "id": "uuid-2",
      "name": "Bob Cat",
      "externalId": null,
      "profileUrl": null,
      "email": "bobc@example.com",
      "custom": {
        "phone": "999-999-9999"
      },
      "updated": "2019-02-21T03:29:00.173452",
      "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg=="
    }
  ]
}
''';

final _getMetadataSuccessResponse = '''{
  "status": 200,
  "data": {
    "id": "uuid-1",
    "name": "John Doe",
    "externalId": null,
    "profileUrl": null,
    "email": "jack@twitter.com",
    "updated": "2019-02-20T23:11:20.893755",
    "eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="
  }
}
''';

final _setUuidMetadataBody =
    '{"name":"John Doe","email":"jack@twitter.com","custom":null,"externalId":null,"profileUrl":null}';

final _setUuidMetadataSuccessResponse = '''{
  "status": 200,
  "data": {
    "id": "uuid-1",
    "name": "John Doe",
    "externalId": null,
    "profileUrl": null,
    "email": "jack@twitter.com",
    "updated": "2019-02-20T23:11:20.893755",
    "eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="
  }
}
''';

final _removeMetadataSuccessResponse = '''{
  "status": 0,
  "data": {}
}
''';
