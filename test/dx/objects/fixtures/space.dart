part of '../space_test.dart';

class FakePubNub implements PubNub {
  List<Invocation> invocations = [];

  FakePubNub();

  @override
  noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

final _createSpaceBody =
    '{"id":"my-channel","name":"My space","description":"A space that is mine","custom":null}';

final _createSpaceSuccessResponse =
    '{"status": 200,"data": {"id": "my-channel","name": "My space","description": "A space that is mine","created": "2019-02-20T23:11:20.893755","updated": "2019-02-20T23:11:20.893755","eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="}}';

final _getAllSpacesSuccessResponse =
    '{ "status": 200, "data": [ { "id": "my-channel", "name": "My space", "description": "A space that is mine", "custom": null, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg==" }, { "id": "main", "name": "Main space", "description": "The main space", "custom": { "public": true, "motd": "Always check your spelling!" }, "created": "2019-02-20T23:11:20.893755", "updated": "2019-02-20T23:11:20.893755", "eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg==" } ], "totalCount": 9, "next": "MUIwQTAwMUItQkRBRC00NDkyLTgyMEMtODg2OUU1N0REMTNBCg==", "prev": "M0FFODRENzMtNjY2Qy00RUExLTk4QzktNkY1Q0I2MUJFNDRCCg==" }';

final _getSpaceSuccessResponse =
    '{"status": 200,"data": {"id": "space-1","name": "My space","description": "A space that is mine","created": "2019-02-20T23:11:20.893755","updated": "2019-02-20T23:11:20.893755","eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="}}';

final _updateSpaceSuccessResponse =
    '{"status": 200,"data": {"id": "space-1","name": "My space","description": "A space that is mine","created": "2019-02-20T23:11:20.893755","updated": "2019-02-20T23:11:20.893755","eTag": "RTc1NUQwNUItREMyNy00Q0YxLUJCNDItMEZDMTZDMzVCN0VGCg=="}}';

final _updateSpaceBody =
    '{"id":"space-1","name":"My space","description":"A space that is mine","custom":null}';

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
