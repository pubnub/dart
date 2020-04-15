part of '../membership_test.dart';

final _getUserMembershipsSuccessResponse =
    '{"status":200,"data":[{"id":"my-channel","custom":{"starred":false},"space":{"id":"my-channel","name":"My space","description":"A space that is mine","created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg==" },"created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RUNDMDUwNjktNUYwRC00RTI0LUI1M0QtNUUzNkE2NkU0MEVFCg=="},{"id":"main","custom":{"starred":true},"space":{"id":"main","name":"Main space","description":"The main space","custom":{"public":true,"motd":"Always check your spelling!" },"created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="},"created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RUNDMDUwNjktNUYwRC00RTI0LUI1M0QtNUUzNkE2NkU0MEVFCg=="}],"totalCount":7,"next":"RDIwQUIwM0MtNUM2Ni00ODQ5LUFGRjMtNDk1MzNDQzE3MUVCCg==","prev":"MzY5RjkzQUQtNTM0NS00QjM0LUI0M0MtNjNBQUFGODQ5MTk2Cg=="}';

final _manageUserMembershipsBody =
    '{"add":[{"id":"space-1"}],"update":[{"id":"space-X","custom":{"expression":"null"}}],"remove":[{"id":"space-2"}]}';

final _addUserMembershipsBody = '{"add":[{"id":"space-1"}]}';

final _removeUserMembershipsBody = '{"remove":[{"id":"space-2"}]}';

final _updateUserMembershipsBody =
    '{"update":[{"id":"space-X","custom":{"expression":"null"}}]}';

final _manageUserMembershipsSuccessResponse =
    '{"status":200,"data":[{"id":"space-1","custom":{"starred":false},"space":{"id":"my-channel","name":"My space","description":"A space that is mine","created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg==" },"created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RUNDMDUwNjktNUYwRC00RTI0LUI1M0QtNUUzNkE2NkU0MEVFCg=="},{"id":"main","custom":{"starred":true},"space":{"id":"main","name":"Main space","description":"The main space","custom":{"public":true,"motd":"Always check your spelling!" },"created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="},"created":"2019-02-20T23:11:20.893755","updated":"2019-02-20T23:11:20.893755","eTag":"RUNDMDUwNjktNUYwRC00RTI0LUI1M0QtNUUzNkE2NkU0MEVFCg=="}],"totalCount":7,"next":"RDIwQUIwM0MtNUM2Ni00ODQ5LUFGRjMtNDk1MzNDQzE3MUVCCg==","prev":"MzY5RjkzQUQtNTM0NS00QjM0LUI0M0MtNjNBQUFGODQ5MTk2Cg=="}';

final _getSpaceMembersSuccessResponse =
    '{ "status": 200, "data": [ { "id": "user-1", "custom": { "role": "admin" }, "user": { "id": "user-1", "name": "John Doe", "externalId": null, "profileUrl": null, "email": "jack@twitter.com", "custom": null, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg==" }, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg==" }, { "id": "user-2", "custom": { "role": "moderator" }, "user": { "id": "user-2", "name": "Bob Cat", "externalId": null, "profileUrl": null, "email": "bobc@example.com", "custom": { "phone": "999-999-9999" }, "created": "2019-02-19T13:10:20.893755", "updated": "2019-02-21T03:29:00.173452", "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg==" }, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg==" } ], "totalCount": 37, "next": "RDIwQUIwM0MtNUM2Ni00ODQ5LUFGRjMtNDk1MzNDQzE3MUVCCg==", "prev": "MzY5RjkzQUQtNTM0NS00QjM0LUI0M0MtNjNBQUFGODQ5MTk2Cg==" }';

final _manageSpaceMembersBody =
    '{"add":[{"id":"user-1"}],"update":[{"id":"user-1","custom":{"address":"null"}}],"remove":[{"id":"user-2"}]}';

final _manageSpaceMembersSuccessResponse =
    '{ "status": 200, "data": [ { "id": "user-1", "custom": { "role": "admin" }, "user": { "id": "user-1", "name": "John Doe", "externalId": null, "profileUrl": null, "email": "jack@twitter.com", "custom": null, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg==" }, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg==" }, { "id": "user-2", "custom": { "role": "moderator" }, "user": { "id": "user-2", "name": "Bob Cat", "externalId": null, "profileUrl": null, "email": "bobc@example.com", "custom": { "phone": "999-999-9999" }, "created": "2019-02-19T13:10:20.893755", "updated": "2019-02-21T03:29:00.173452", "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg==" }, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "QkRENDA5MjItMUZCNC00REI5LUE4QTktRjJGNUMxNTc2MzE3Cg==" } ], "totalCount": 37, "next": "RDIwQUIwM0MtNUM2Ni00ODQ5LUFGRjMtNDk1MzNDQzE3MUVCCg==", "prev": "MzY5RjkzQUQtNTM0NS00QjM0LUI0M0MtNjNBQUFGODQ5MTk2Cg==" }';

final _commonObjectError = '''{
    "status": 500,
    "error": {
        "message": "An unexpected error ocurred while processing the request.",
        "source": "objects"
    }
}''';
