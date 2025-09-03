part of '../app_context_test.dart';

final _setUUIDMetadataBody = '''{"name":"test","custom":{"hello":"world"}}''';

final _setChannelMetadataBody =
    '''{"name":"channel name","description":"channel description","custom":{"string-key":"string-value"}}''';

final _setChannelMemberMetadataBody =
    '''{"set":[{"uuid":{"id":"test"},"custom":{"role":"admin"}}]}''';

final _setChannelMembershipMetadataBody =
    '''{"set":[{"channel":{"id":"test"},"custom":{"starred":"false"}}]}''';

final _setChannelMembershipMetadataResponse =
    '''{"status":200,"data":[{"channel":{"id":"test","name":"channel name","description":"channel description","updated":"2025-06-22T15:07:48.219044Z","eTag":"1a24f01cbd01190c183865ec5e9c588b"},"type":null,"status":null,"updated":"2025-06-22T17:42:12.919343Z","eTag":"AfzM4PeLkOrk2wE"}],"totalCount":1,"next":"MQ"}''';

final _setChannelMemberMetadataResponse =
    '''{"status":200,"data":[{"uuid":{"id":"test"},"type":null,"status":null,"updated":"2025-06-22T17:14:28.972756Z","eTag":"Acr+lIO/3JX93wE"}],"totalCount":1,"next":"MQ"}''';

final _setChannelMetadataResponse = '''{
  "status": 200,
  "data": {
    "id": "s",
    "name": "channel name",
    "description": "channel description",
    "type": null,
    "status": null,
    "updated": "2025-06-22T15:07:48.219044Z",
    "eTag": "1a24f01cbd01190c183865ec5e9c588b"
  }
}
''';

final _setUUIDMetadataResponse = '''
    {"status":200,
    "data":{"id":"test",
    "name":"test",
    "externalId":null,
    "profileUrl":null,
    "email":null,
    "type":null,
    "status":null,
    "updated":"2025-06-21T12:16:59.141778Z",
    "eTag":"bf0ce352ea8c620e0cc83bcce8121f2f"}}
''';

// Objects API test fixtures

// UUID Metadata fixtures
final getAllUuidMetadataResponse = '''{
  "status": 200,
  "data": [
    {
      "id": "uuid1",
      "name": "Test User 1",
      "externalId": "ext1",
      "profileUrl": "https://example.com/avatar1.jpg",
      "email": "user1@example.com",
      "custom": {
        "role": "admin",
        "department": "engineering"
      },
      "updated": "2023-01-01T12:00:00.000Z",
      "eTag": "etag1"
    },
    {
      "id": "uuid2", 
      "name": "Test User 2",
      "externalId": "ext2",
      "profileUrl": "https://example.com/avatar2.jpg",
      "email": "user2@example.com",
      "custom": {
        "role": "user",
        "department": "marketing"
      },
      "updated": "2023-01-02T12:00:00.000Z",
      "eTag": "etag2"
    }
  ],
  "totalCount": 2,
  "next": "nextCursor",
  "prev": "prevCursor"
}''';

final getAllUuidMetadataEmptyResponse = '''{
  "status": 200,
  "data": [],
  "totalCount": 0,
  "next": null,
  "prev": null
}''';

final getUuidMetadataResponse = '''{
  "status": 200,
  "data": {
    "id": "test-uuid",
    "name": "Test User",
    "externalId": "external-123",
    "profileUrl": "https://example.com/avatar.jpg",
    "email": "test@example.com",
    "custom": {
      "role": "admin",
      "active": true,
      "score": 95.5
    },
    "updated": "2023-01-01T12:00:00.000Z",
    "eTag": "test-etag-123"
  }
}''';

final setUuidMetadataBody =
    '''{"name":"Updated User","email":"updated@example.com","custom":{"role":"manager","active":true,"score":88.5},"externalId":"ext-456","profileUrl":"https://example.com/new-avatar.jpg"}''';

final setUuidMetadataResponse = '''{
  "status": 200,
  "data": {
    "id": "test-uuid",
    "name": "Updated User",
    "externalId": "ext-456",
    "profileUrl": "https://example.com/new-avatar.jpg", 
    "email": "updated@example.com",
    "custom": {
      "role": "manager",
      "active": true,
      "score": 88.5
    },
    "updated": "2023-01-01T13:00:00.000Z",
    "eTag": "updated-etag-123"
  }
}''';

final removeUuidMetadataResponse = '''{
  "status": 200
}''';

// Channel Metadata fixtures
final getAllChannelMetadataResponse = '''{
  "status": 200,
  "data": [
    {
      "id": "channel1",
      "name": "Test Channel 1",
      "description": "First test channel",
      "custom": {
        "category": "public",
        "priority": 1
      },
      "updated": "2023-01-01T12:00:00.000Z",
      "eTag": "ch-etag1"
    },
    {
      "id": "channel2",
      "name": "Test Channel 2", 
      "description": "Second test channel",
      "custom": {
        "category": "private",
        "priority": 2
      },
      "updated": "2023-01-02T12:00:00.000Z",
      "eTag": "ch-etag2"
    }
  ],
  "totalCount": 2,
  "next": "ch-nextCursor",
  "prev": "ch-prevCursor"
}''';

final getChannelMetadataResponse = '''{
  "status": 200,
  "data": {
    "id": "test-channel",
    "name": "Test Channel",
    "description": "A test channel description",
    "custom": {
      "category": "test",
      "priority": 5,
      "active": true
    },
    "updated": "2023-01-01T12:00:00.000Z",
    "eTag": "channel-etag-123"
  }
}''';

final setChannelMetadataBody =
    '''{"name":"Updated Channel","description":"Updated channel description","custom":{"category":"updated","priority":10,"active":false}}''';

final setChannelMetadataResponse = '''{
  "status": 200,
  "data": {
    "id": "test-channel",
    "name": "Updated Channel",
    "description": "Updated channel description",
    "custom": {
      "category": "updated",
      "priority": 10,
      "active": false
    },
    "updated": "2023-01-01T13:00:00.000Z",
    "eTag": "updated-channel-etag"
  }
}''';

final removeChannelMetadataResponse = '''{
  "status": 200
}''';

// Membership fixtures
final getMembershipsResponse = '''{
  "status": 200,
  "data": [
    {
      "channel": {
        "id": "channel1",
        "name": "Channel 1",
        "description": "First channel",
        "custom": {
          "type": "public"
        }
      },
      "custom": {
        "role": "member",
        "joined": "2023-01-01"
      },
      "updated": "2023-01-01T12:00:00.000Z",
      "eTag": "membership-etag1"
    },
    {
      "channel": {
        "id": "channel2", 
        "name": "Channel 2",
        "description": "Second channel",
        "custom": {
          "type": "private"
        }
      },
      "custom": {
        "role": "admin",
        "joined": "2023-01-02"
      },
      "updated": "2023-01-02T12:00:00.000Z",
      "eTag": "membership-etag2"
    }
  ],
  "totalCount": 2,
  "next": "membership-next",
  "prev": "membership-prev"
}''';

final setMembershipsBody =
    '''{"set":[{"channel":{"id":"new-channel"},"custom":{"role":"member","notifications":true}}]}''';

final manageMembershipsBody =
    '''{"set":[{"channel":{"id":"add-channel"},"custom":{"role":"member"}}],"delete":[{"channel":{"id":"remove-channel"}}]}''';

final removeMembershipsBody =
    '''{"delete":[{"channel":{"id":"channel-to-remove"}},{"channel":{"id":"another-channel-to-remove"}}]}''';

// Channel Members fixtures
final getChannelMembersResponse = '''{
  "status": 200,
  "data": [
    {
      "uuid": {
        "id": "uuid1",
        "name": "User 1",
        "custom": {
          "department": "engineering"
        }
      },
      "custom": {
        "role": "admin",
        "permissions": ["read", "write", "delete"]
      },
      "updated": "2023-01-01T12:00:00.000Z",
      "eTag": "member-etag1"
    },
    {
      "uuid": {
        "id": "uuid2",
        "name": "User 2", 
        "custom": {
          "department": "marketing"
        }
      },
      "custom": {
        "role": "member",
        "permissions": ["read"]
      },
      "updated": "2023-01-02T12:00:00.000Z",
      "eTag": "member-etag2"
    }
  ],
  "totalCount": 2,
  "next": "members-next",
  "prev": "members-prev"
}''';

final setChannelMembersBody =
    '''{"set":[{"uuid":{"id":"new-member-uuid"},"custom":{"role":"member","invited_by":"admin-uuid"}}]}''';

final manageChannelMembersBody =
    '''{"set":[{"uuid":{"id":"add-member-uuid"},"custom":{"role":"member"}}],"delete":[{"uuid":{"id":"remove-member-uuid"}}]}''';

final removeChannelMembersBody =
    '''{"delete":[{"uuid":{"id":"member-to-remove"}}]}''';

// Error response fixtures
final unauthorizedErrorResponse = '''{
  "status": 401,
  "error": {
    "message": "Invalid subscribe key",
    "code": 401
  }
}''';

final forbiddenErrorResponse = '''{
  "status": 403,
  "error": {
    "message": "Forbidden",
    "code": 403
  }
}''';

final notFoundErrorResponse = '''{
  "status": 404,
  "error": {
    "message": "Resource not found",
    "code": 404
  }
}''';

final preconditionFailedErrorResponse = '''{
  "status": 412,
  "error": {
    "message": "Precondition Failed - ETag mismatch",
    "code": 412
  }
}''';

final rateLimitErrorResponse = '''{
  "status": 429,
  "error": {
    "message": "Too Many Requests",
    "code": 429
  }
}''';

final internalServerErrorResponse = '''{
  "status": 500,
  "error": {
    "message": "Internal Server Error",
    "code": 500
  }
}''';

// Test input data
class ObjectsTestData {
  static final validUuidMetadata = {
    'name': 'Test User',
    'email': 'test@example.com',
    'externalId': 'ext-123',
    'profileUrl': 'https://example.com/avatar.jpg',
    'custom': {'role': 'admin', 'active': true, 'score': 95.5, 'tags': null}
  };

  static final validChannelMetadata = {
    'name': 'Test Channel',
    'description': 'A test channel',
    'custom': {'category': 'test', 'priority': 5, 'public': true}
  };

  static final validMembershipMetadata = {
    'channelId': 'test-channel',
    'custom': {'role': 'member', 'notifications': true}
  };

  static final validChannelMemberMetadata = {
    'uuid': 'test-uuid',
    'custom': {
      'role': 'admin',
      'permissions': ['read', 'write']
    }
  };

  static final invalidCustomFieldsArray = {
    'custom': {
      'invalid': [1, 2, 3] // Arrays not allowed
    }
  };

  static final invalidCustomFieldsObject = {
    'custom': {
      'invalid': {'nested': 'object'} // Objects not allowed
    }
  };
}
