part of '../user_test.dart';

class FakePubNub implements PubNub {
  List<Invocation> invocations = [];

  FakePubNub();

  @override
  noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

final _createuserBody =
    '{"id":"user-1","name":"Name 1","email":"email@email.com","custom":null,"externalId":null,"profileUrl":null}';

final _createUserSuccessResponse =
    '{"status": 200,"data": {"id": "user-1","name": "Name 1","externalId": null,"profileUrl": null,"email": "email@email.com","created": "2019-02-20T23:11:20.893755","updated": "2019-02-20T23:11:20.893755","eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="}}';

final _getAllUserSuccessResponse =
    '{"status": 200,"data":[{"id": "user-1","name": "Name 1","externalId": null,"profileUrl": null,"email": "email@email.com","created": "2019-02-20T23:11:20.893755","updated": "2019-02-20T23:11:20.893755","eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="}]}';

final _getUserSuccessResponse =
    '{"status": 200,"data":{"id": "user-1","name": "Name 1","externalId": null,"profileUrl": null,"email": "email@email.com","created": "2019-02-20T23:11:20.893755","updated": "2019-02-20T23:11:20.893755","eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="}}';

final _updateUserBody =
    '{"id":"user-1","name":"Name 1","email":"email@email.com","custom":null,"externalId":null,"profileUrl":null}';

final _updateUserSuccessResponse =
    '{"status": 200,"data":{"id": "user-1","name": "Name 1","externalId": null,"profileUrl": null,"email": "email@email.com","created": "2019-02-20T23:11:20.893755","updated": "2019-02-20T23:11:20.893755","eTag": "MDcyQ0REOTUtNEVBOC00QkY2LTgwOUUtNDkwQzI4MjgzMTcwCg=="}}';
final _httpError400 = '''{
    "status": 400,
    "error": {
        "message": "Request payload contained invalid input.",
        "source": "objects",
        "details": [
            {
                "message": "User email must be a valid email address.",
                "location": "user.email",
                "locationType": "body"
            }
        ]
    }
}''';

final _commonObjectError = '''{
    "status": 500,
    "error": {
        "message": "An unexpected error ocurred while processing the request.",
        "source": "objects"
    }
}''';
