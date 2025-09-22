part of '../channel_group_test.dart';

// Successful responses
final _listChannelsSuccessResponse = '''{
  "status": 200,
  "payload": {
    "group": "cg1",
    "channels": ["ch1", "ch2", "ch3"]
  }
}''';

final _listChannelsEmptyResponse = '''{
  "status": 200,
  "payload": {
    "group": "empty_group",
    "channels": []
  }
}''';

final _addChannelsSuccessResponse = '''{
  "status": 200,
  "message": "OK",
  "service": "channel-registry",
  "error": false
}''';

final _removeChannelsSuccessResponse = '''{
  "status": 200,
  "message": "OK",
  "service": "channel-registry",
  "error": false
}''';

final _deleteChannelGroupSuccessResponse = '''{
  "status": 200,
  "message": "OK",
  "service": "channel-registry",
  "error": false
}''';

// Error responses
final _forbiddenErrorResponse = '''{
  "status": 403,
  "message": "Forbidden",
  "error": true,
  "service": "Access Manager",
  "payload": {
    "message": "Insufficient permissions"
  }
}''';

final _invalidArgumentsErrorResponse = '''{
  "status": 400,
  "message": "Invalid Arguments",
  "error": true,
  "service": "channel-registry"
}''';

final _malformedJsonResponse = '''{"invalid": json syntax''';
