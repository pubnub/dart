part of '../message_action_test.dart';

// Mock response templates for message action tests

const addMessageActionSuccessResponse = '''
{
  "status": 200,
  "data": {
    "type": "reaction",
    "value": "smiley_face", 
    "actionTimetoken": "15610547826970051",
    "messageTimetoken": "15610547826970050",
    "uuid": "test-uuid"
  }
}
''';

const fetchMessageActionsSuccessResponse = '''
{
  "status": 200,
  "data": [
    {
      "type": "reaction",
      "value": "smiley_face",
      "actionTimetoken": "15610547826970051",
      "messageTimetoken": "15610547826970050", 
      "uuid": "test-uuid"
    },
    {
      "type": "custom",
      "value": "star",
      "actionTimetoken": "15610547826970052",
      "messageTimetoken": "15610547826970050", 
      "uuid": "test-uuid"
    }
  ],
  "more": {
    "url": "/v1/message-actions/demo/channel/test?start=15610547826970051",
    "start": "15610547826970051",
    "end": "15610547826970100",
    "limit": 100
  }
}
''';

const fetchMessageActionsEmptyResponse = '''
{
  "status": 200,
  "data": [],
  "more": null
}
''';

final fetchMessageActionsSingle100Response = '''
{
  "status": 200,
  "data": [''' +
    List.generate(
        100,
        (i) => '''
    {
      "type": "reaction",
      "value": "smiley_face",
      "actionTimetoken": "${15610547826970051 + i}",
      "messageTimetoken": "15610547826970050", 
      "uuid": "test-uuid"
    }''').join(',') +
    '''
  ],
  "more": {
    "url": "/v1/message-actions/demo/channel/test?start=15610547826970151",
    "start": "15610547826970151",
    "end": "15610547826970200",
    "limit": 100
  }
}
''';

const deleteMessageActionSuccessResponse = '''
{
  "status": 200,
  "data": {}
}
''';

// Error responses
const messageAction400ErrorResponse = '''
{
  "error": true,
  "message": "Invalid request",
  "status": 400
}
''';

const messageAction403ErrorResponse = '''
{
  "error": true, 
  "message": "Forbidden",
  "status": 403
}
''';

const messageAction404ErrorResponse = '''
{
  "error": true,
  "message": "Not Found", 
  "status": 404
}
''';

const malformedJsonResponse = '''
{
  "data": [
    {
      "type": "reaction"
      "value": "missing_comma",
      "actionTimetoken": "15610547826970051"
''';

const missingFieldsResponse = '''
{
  "status": 200,
  "data": {
    "type": "reaction"
  }
}
''';
