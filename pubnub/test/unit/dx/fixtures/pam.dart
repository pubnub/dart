part of '../pam_test.dart';

final _grantRequest = MockRequest('GET',
    'v2/auth/grant/sub-key/test?auth=authKey&channel=my_channel&ttl=1440&m=0&r=1&w=0&pnsdk=PubNub-Dart%2F${PubNub.version}&timestamp=1234567890&signature=v2.GeR1r2jVlxg-5zv7SnS176bbIqqya3jIoJ8cH0YDJtU');

final _grantSuccessResponse =
    MockResponse(statusCode: 200, headers: {}, body: '''
{
    "status": 200,
    "message": "Success",
    "payload": {
        "ttl": 1440,
        "auths": {
            "password": {
                "r": 1,
                "w": 0,
                "m": 0,
                "d": 0
            }
        },
        "subscribe_key": "{subscribe-key}",
        "level": "user",
        "channel": "my_channel"
    },
    "service": "Access Manager"
}
''');

final _grantTokenRequest = MockRequest(
    'POST',
    'v3/pam/test/grant?timestamp=1234567890&pnsdk=PubNub-Dart%2F${PubNub.version}&signature=v2.5kWsV-b4rDjsFxiccnB64OMnHq8fdVaS7mlEWPU2Uuw',
    {},
    '{"ttl":1440,"permissions":{"resources":{"channels":{"inbox-jay":3},"groups":{},"users":{},"spaces":{}},"patterns":{"channels":{},"groups":{},"users":{},"spaces":{}},"meta":{"user-id":"jay@example.com","contains-unicode":"The 來 test."}}}');

final _grantTokenSuccessResponse =
    MockResponse(statusCode: 200, headers: {}, body: '''{
  "status": 200,
  "data": {
    "message": "Success",
    "token": "p0F2AkF0Gl6ZkldDdHRsGQWgQ3Jlc6REY2hhbqFpaW5ib3gtamF5A0NncnCgQ3VzcqBDc3BjoENwYXSkRGNoYW6gQ2dycKBDdXNyoENzcGOgRG1ldGGiZ3VzZXItaWRvamF5QGV4YW1wbGUuY29tcGNvbnRhaW5zLXVuaWNvZGVtVGhlIOS-hiB0ZXN0LkNzaWdYID3ahuVZSAmm-P4eR2KPay9KqahygKQbB9Uldx0LW2em"
  },
  "service": "Access Manager"
}''');

final _grantTokenFailureResponse =
    MockResponse(statusCode: 400, headers: {}, body: '''
{
    "status": 400,
    "error": {
        "message": "Invalid ttl",
        "source": "authz",
        "details": [
        {
            "message": "Valid range is 1 minute to 30 days.",
            "location": "ttl",
            "locationType": "body"
        }
        ]
    },
    "service": "Access Manager"
}''');
