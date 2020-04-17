part of '../pam_test.dart';

final _grantRequest = MockRequest('GET',
    'v2/auth/grant/sub-key/test?auth=authKey&channel=my_channel&ttl=1440&timestamp=1234567890&m=0&r=1&w=0&pnsdk=PubNub-Dart%2F${PubNub.version}&signature=7IQCgpg73TUef0vywNJLvK27qrYKxKgvWUueR_Kej9U%3D');

final _grantSuccessResponse = MockResponse(200, {}, '''
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
    'v3/pam/test/grant?timestamp=1234567890&pnsdk=PubNub-Dart%2F${PubNub.version}&signature=v2.FL8sKKLo_xIlZnTV47foJdbUYUIWCtvYP4IqJzKVnKU',
    {},
    '{"ttl":1440,"permissions":{"resources":{"channels":{"inbox-jay":3},"groups":{},"users":{},"spaces":{}},"patterns":{"channels":{},"groups":{},"users":{},"spaces":{}},"meta":{"user-id":"jay@example.com","contains-unicode":"The 來 test."}}}');

final _grantTokenSuccessResponse = MockResponse(200, {}, '''{
  "status": 200,
  "data": {
    "message": "Success",
    "token": "p0F2AkF0Gl6ZkldDdHRsGQWgQ3Jlc6REY2hhbqFpaW5ib3gtamF5A0NncnCgQ3VzcqBDc3BjoENwYXSkRGNoYW6gQ2dycKBDdXNyoENzcGOgRG1ldGGiZ3VzZXItaWRvamF5QGV4YW1wbGUuY29tcGNvbnRhaW5zLXVuaWNvZGVtVGhlIOS-hiB0ZXN0LkNzaWdYID3ahuVZSAmm-P4eR2KPay9KqahygKQbB9Uldx0LW2em"
  },
  "service": "Access Manager"
}''');

final _grantTokenFailureResponse = MockResponse(400, {}, '''
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
