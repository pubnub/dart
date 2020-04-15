part of '../history_test.dart';

final _batchFetchMessagesSuccessResponse = '''{
  "error":false,
  "status":200,
  "error_message":"",
  "channels":{"test-1":[{"message": 42, "timestamp": 1231231231231}], "test-2": [{"message": 10, "timestamp": 1231231231231}]}
}''';

final _batchCountMessagesSuccessResponse = '''{
  "error": false,
  "status": 200,
  "error_message": "",
  "channels": {"test-1": 42, "test-2": 10}
}''';
