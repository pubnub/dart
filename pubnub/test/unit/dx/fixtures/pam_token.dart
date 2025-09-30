part of '../pam_token_test.dart';

// PLAN_CASE: Successful token grant response fixture
const _grantTokenSuccessResponse = '''
{
  "status": 200,
  "data": {
    "message": "Success",
    "token": "qEF2AkF0GmEI03xDdHRsGDxDcmVzpURjaGFuoWljaGFubmVsLTEY70NncnChb2NoYW5uZWxfZ3JvdXAtMQVkdXVpZHOhZnV1aWQtMRhoQ3BhdKVEY2hhbqFtXmNoYW5uZWwtLiokGO9DZ3JwoWpjaGFubmVsLWdyb3VwLSQkGAVkdXVpZHOhZnV1aWQtLiokGGhEbWV0YaBEdXVpZHN0ZXN0LWF1dGhvcml6ZWQtdXVpZERzaWdYIPpU-vCe9rkpYs87YUrFNWkyNq8CVvmKwEjVinnDrJJc"
  }
}
''';

// PLAN_CASE: Error response fixture for invalid permissions
const _grantTokenErrorResponse = '''
{
  "status": 400,
  "error": {
    "message": "Invalid permissions",
    "source": "grant",
    "details": [
      {
        "message": "Invalid resource type",
        "location": "permissions.resources",
        "locationType": "body"
      }
    ]
  }
}
''';

// PLAN_CASE: Error response fixture for missing secret key
const _grantTokenMissingSecretKeyResponse = '''
{
  "status": 403,
  "error": {
    "message": "Forbidden",
    "source": "grant",
    "details": [
      {
        "message": "Secret key required for PAM operations",
        "location": "keyset",
        "locationType": "authentication"
      }
    ]
  }
}
''';

// PLAN_CASE: Complex token request payload with multiple resources
const _complexTokenRequestPayload = '''
{
  "ttl": 1440,
  "permissions": {
    "resources": {
      "channels": {
        "channel-1": 3,
        "channel-2": 7
      },
      "groups": {
        "group-1": 1
      },
      "uuids": {
        "user-1": 15
      }
    },
    "patterns": {
      "channels": {
        "channel-.*": 3
      },
      "groups": {
        "group-.*": 1
      }
    },
    "uuid": "authorized-user-123",
    "meta": {
      "user-id": "test@example.com",
      "role": "admin"
    }
  }
}
''';

// PLAN_CASE: Simple token request payload
const _simpleTokenRequestPayload = '''
{
  "ttl": 60,
  "permissions": {
    "resources": {
      "channels": {
        "test-channel": 3
      },
      "groups": {},
      "uuids": {}
    },
    "patterns": {
      "channels": {},
      "groups": {},
      "uuids": {}
    }
  }
}
''';

// PLAN_CASE: Token request with patterns only
const _patternTokenRequestPayload = '''
{
  "ttl": 720,
  "permissions": {
    "resources": {
      "channels": {},
      "groups": {},
      "uuids": {}
    },
    "patterns": {
      "channels": {
        "chat-.*": 7
      },
      "groups": {
        "admin-.*": 15
      },
      "uuids": {}
    },
    "uuid": "pattern-user"
  }
}
''';

// PLAN_CASE: User/Space resource type token request
const _userSpaceTokenRequestPayload = '''
{
  "ttl": 300,
  "permissions": {
    "resources": {
      "channels": {},
      "groups": {},
      "uuids": {
        "user-123": 31,
        "space-456": 7
      }
    },
    "patterns": {
      "channels": {},
      "groups": {},
      "uuids": {}
    },
    "uuid": "space-authorized-user"
  }
}
''';
