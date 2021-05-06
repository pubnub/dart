part of '../message_action_test.dart';

final _addMessageActionResponse = ''' 
{
  "status": 200,
  "data": {
    "type": "reaction",
    "value": "smiley_face",
    "actionTimetoken": "15610547826970050",
    "messageTimetoken": "15610547826969050",
    "uuid": "terryterry69420"
  }
}''';

final _addMessageActionBody = '{"type":"reaction","value":"smiley_face"}';

final _fetchMessageActionsResponse = '''
{
  "status": 200,
  "data": [
    {
      "type": "reaction",
      "value": "smiley_face",
      "actionTimetoken": "15610547826970050",
      "messageTimetoken": "15610547826969050",
      "uuid": "terryterry69420"
    }
  ]
}''';

final _fetchMessageActionsResponseWithMoreField = '''
{
  "status": 200,
  "data": [
    {
      "type": "reaction",
      "value": "smiley_face",
      "actionTimetoken": "15610547826970050",
      "messageTimetoken": "15610547826969050",
      "uuid": "terryterry69420"
    }
  ],
  "more": {
    "url": "v1/message-actions/test/channel/test?start=15610547826970050&end=15645905639093361&limit=2",
    "start": "15610547826970050",
    "end": "15645905639093361",
    "limit": 2
  }
}
''';

final _deleteMessageActionResponse = '''
{
  "status": 200,
  "data": {}
}''';

final _failedToPublishErrorResponse = '''{
  "status": 207,
  "data": {
    "type": "reaction",
    "value": "smiley_face",
    "uuid": "user-456",
    "actionTimetoken": 15610547826970050,
    "messageTimetoken": 15610547826969050
  },
  "error": {
    "message": "Stored but failed to publish message action.",
    "source": "actions"
  }
}''';

final _invalidParameterErrorResponse = '''{
  "status": 400,
  "error": {
    "source": "actions",
    "message": "Request payload contained invalid input.",
    "details": [
      {
        "message": "Missing field",
        "location": "value",
        "locationType": "body"
      }
    ]
  }
}''';

final _unauthorizeErrorResponse = '''{
  "status": 403,
  "error": {
    "source": "actions",
    "message": "Supplied authorization key does not have the permissions required to perform this operation."
  }
}''';

final _fetchMessageActionError = '''{
  "status": 400,
  "error": {
    "source": "actions",
    "message": "Invalid Subkey"
  }
}''';
