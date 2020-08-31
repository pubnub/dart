part of '../history_test.dart';

final _batchFetchMessagesSuccessResponse = '''{
  "error":false,
  "status":200,
  "error_message":"",
  "channels":{"test-1":[{"message": 42, "timetoken": "1231231231231"}], "test-2": [{"message": 10, "timetoken": "1231231231231"}]}
}''';

final _batchCountMessagesSuccessResponse = '''{
  "error": false,
  "status": 200,
  "error_message": "",
  "channels": {"test-1": 42, "test-2": 10}
}''';

final _batchFetchMessagesWithActionSuccessResponse = '''{
  "status": 200,
  "error": false,
  "error_message": "",
  "channels": {
    "demo-channel": [
      {
        "message": "Hi",
        "timetoken": "15610547826970040",
        "actions": {
          "receipt": {
            "read": [
              {
                "uuid": "user-7",
                "actionTimetoken": 15610547826970044
              }
            ]
          }
        }
      },
      {
        "message": "Hello",
        "timetoken": "15610547826970000",
        "actions": {
          "reaction": {
            "smiley_face": [
              {
                "uuid": "user-456",
                "actionTimetoken": 15610547826970050
              }
            ],
            "poop_pile": [
              {
                "uuid": "user-789",
                "actionTimetoken": 15610547826980050
              },
              {
                "uuid": "user-567",
                "actionTimetoken": 15610547826970000
              }
            ]
          }
        }
      }
    ]
  }
}''';

final _batchFetchMessagesWithActionsWithMore = '''{
  "status": 200,
  "error": false,
  "error_message": "",
  "channels": {
    "demo-channel": [
      {
        "message": "Hi",
        "timetoken": "15610547826970040",
        "actions": {
          "receipt": {
            "read": [
              {
                "uuid": "user-7",
                "actionTimetoken": 15610547826970044
              }
            ]
          }
        }
      },
      {
        "message": "Hello",
        "timetoken": "15610547826970000",
        "actions": {
          "reaction": {
            "smiley_face": [
              {
                "uuid": "user-456",
                "actionTimetoken": 15610547826970050
              }
            ],
            "poop_pile": [
              {
                "uuid": "user-789",
                "actionTimetoken": 15610547826980050
              },
              {
                "uuid": "user-567",
                "actionTimetoken": 15610547826970000
              }
            ]
          }
        }
      }
    ]
  },
  "more": {
    "url": "/v1/history-with-actions/s/channel/c?start=15610547826970000&limit=98",
    "start": "15610547826970000",
    "limit": 98
  }
}
''';
