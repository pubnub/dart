part of '../membership_metadata_test.dart';

final _membershipsMetadataSuccessResponse = '''{
  "status": 200,
  "data": [
    {
      "channel": {
        "id": "my-channel",
        "name": "My channel",
        "description": "A channel that is mine",
        "custom": null,
        "updated": "2019-02-20T23:11:20.893755",
        "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="
      },
      "custom": {
        "starred": false
      },
      "updated": "2019-02-20T23:11:20.893755",
      "eTag": "RUNDMDUwNjktNUYwRC00RTI0LUI1M0QtNUUzNkE2NkU0MEVFCg=="
    },
    {
      "channel": {
        "id": "main",
        "name": "Main channel",
        "description": "The main channel",
        "custom": {
          "public": true,
          "motd": "Always check your spelling!"
        },
        "updated": "2019-02-20T23:11:20.893755",
        "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="
      },
      "updated": "2019-02-20T23:11:20.893755",
      "eTag": "RUNDMDUwNjktNUYwRC00RTI0LUI1M0QtNUUzNkE2NkU0MEVFCg=="
    }
  ],
  "totalCount": 7,
  "next": "RDIwQUIwM0MtNUM2Ni00ODQ5LUFGRjMtNDk1MzNDQzE3MUVCCg==",
  "prev": "MzY5RjkzQUQtNTM0NS00QjM0LUI0M0MtNjNBQUFGODQ5MTk2Cg=="
}''';
final _manageMemershipMetadataBody =
    '{"set":[{"channel":{"id":"my-channel"},"custom":{"starred":false}}],"delete":[{"channel":{"id":"channel-1"}}]}';

final _setMemershipsMetadataBody =
    '{"set":[{"channel":{"id":"my-channel"},"custom":{"starred":false}}]}';

final _removeMemershipsMetadataBody =
    '{"delete":[{"channel":{"id":"channel-1"}}]}';

final _membersMetadataSuccessResponse = '''{
  "status": 200,
  "data": [
    {
      "uuid": {
        "id": "uuid-1",
        "name": "John Doe",
        "externalId": null,
        "profileUrl": null,
        "email": "jack@twitter.com",
        "custom": null,
        "updated": "2019-02-20T23:11:20.893755",
        "eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="
      },
      "custom": {
        "role": "admin"
      },
      "updated": "2019-02-20T23:11:20.893755",
      "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg=="
    },
    {
      "uuid": {
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
      },
      "updated": "2019-02-20T23:11:20.893755",
      "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg=="
    }
  ],
  "totalCount": 37,
  "next": "RDIwQUIwM0MtNUM2Ni00ODQ5LUFGRjMtNDk1MzNDQzE3MUVCCg==",
  "prev": "MzY5RjkzQUQtNTM0NS00QjM0LUI0M0MtNjNBQUFGODQ5MTk2Cg=="
}''';

final _manageMemersMetadataBody =
    '{"set":[{"uuid":{"id":"uuid-1"},"custom":{"role":"admin"}}],"delete":[{"uuid":{"id":"uuid-1"}}]}';

final _setMembersMetadataBody =
    '{"set":[{"uuid":{"id":"uuid-1"},"custom":{"role":"admin"}}]}';

final _removeMembersMetadataBody = '{"delete":[{"uuid":{"id":"uuid-2"}}]}';
