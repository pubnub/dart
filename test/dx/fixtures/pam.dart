part of '../pam_test.dart';

final _grantSuccessResponse = '''
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
''';

final _grantTokenBody =
    '{"ttl":1440,"resources":{"channels":{"inbox-jay":3},"groups":{},"users":{},"spaces":{}},"patterns":{"channels":{},"groups":{},"users":{},"spaces":{}},"meta":{"user-id":"jay@example.com","contains-unicode":"The 來 test."}}';

final _grantTokenSuccessResponse = '''
{
    "ttl": 1440,
    "permissions": {
        "resources" : {
            "channels": {
                "inbox-jay": 3
            },
            "groups": {},
            "users": {},
            "spaces": {}
        },
        "patterns" : {
            "channels": {},
            "groups": {},
            "users": {},
            "spaces": {}
        },
        "meta": {
            "user-id": "jay@example.com",
            "contains-unicode": "The 來 test."
        }
    }
}
''';

final _grantTokenErrorResponse = '''
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
}''';

final _tokenWithUserandSpaceInfo =
    'p0F2AkF0Gl2BgxZDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhZXVzZXIxAUNzcGOhZnNwYWNlMQFDcGF0pERjaGFuoENncnCgQ3VzcqFiLioBQ3NwY6FiLioBRG1ldGGgQ3NpZ1ggG1j7rl-TpxtWYDIcPFvR-cqFGXVWvm8r5YBaCLhy5-Y=';

final _multipleTokensSet = <String>{
  'p0F2AkF0Gl2Bd7BDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhZXVzZXIxAUNzcGOgQ3BhdKREY2hhbqBDZ3JwoEN1c3KgQ3NwY6BEbWV0YaBDc2lnWCABo0jeW03hedEyKmtzJBZZijmt5J7GYJ3X_7VuKbYu7Q==',
  'p0F2AkF0Gl2Bd_VDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KgQ3NwY6Fmc3BhY2UxAUNwYXSkRGNoYW6gQ2dycKBDdXNyoENzcGOgRG1ldGGgQ3NpZ1gg6CscU5C58NHVuuQnW8oFkf8BAZ4VbdCuuWtwZRS6lnY='
};

final _userPermissionToken =
    'p0F2AkF0Gl2Bd7BDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhZXVzZXIxAUNzcGOgQ3BhdKREY2hhbqBDZ3JwoEN1c3KgQ3NwY6BEbWV0YaBDc2lnWCABo0jeW03hedEyKmtzJBZZijmt5J7GYJ3X_7VuKbYu7Q==';

final _userInfoNewToken =
    'p0F2AkF0Gl2BgxZDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhZXVzZXIxAUNzcGOhZnNwYWNlMQFDcGF0pERjaGFuoENncnCgQ3VzcqFiLioBQ3NwY6FiLioBRG1ldGGgQ3NpZ1ggG1j7rl-TpxtWYDIcPFvR-cqFGXVWvm8r5YBaCLhy5-Y=';

final _multipleUsersTokensSet = <String>{
  'p0F2AkF0Gl2Bd7BDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhZXVzZXIxAUNzcGOgQ3BhdKREY2hhbqBDZ3JwoEN1c3KgQ3NwY6BEbWV0YaBDc2lnWCABo0jeW03hedEyKmtzJBZZijmt5J7GYJ3X_7VuKbYu7Q==',
  'p0F2AkF0Gl2BeUVDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KhZXVzZXIyAUNzcGOgQ3BhdKREY2hhbqBDZ3JwoEN1c3KgQ3NwY6BEbWV0YaBDc2lnWCBJvm-ZwNdKLcS8vaoq2SAcvZ0HOI2OY6G6nGC-xKuzIg=='
};

final _tokenWithMultipleResourceTypes =
    'p0F2AkF0Gl2Be_hDdHRsGQWgQ3Jlc6REY2hhbqBDZ3JwoEN1c3KgQ3NwY6BDcGF0pERjaGFuoENncnCgQ3VzcqFiLioBQ3NwY6FiLioBRG1ldGGgQ3NpZ1ggF985UuGyc1TXUaEK3pPBNaPc642ynEFHB4hNDUJ3dBs=';
