part of '../channel_test.dart';

class FakePubNub implements PubNub {
  List<Invocation> invocations = [];

  FakePubNub();

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

final _historyMoreSuccessResponse = '''[
  [{"message":42, "timestamp": 1}],
  10,
  20
]''';

final _historyMessagesCountResponse = '''{
  "status": 200,
  "error": false,
  "message": "",
  "channels": {
    "test": 42
  }
}''';

final _historyMessagesDeleteResponse = '''{
  "status": 200,
  "error": false,
  "message": ""
}''';

final _historyMessagesFetchResponse = '''[
  [{"message":42, "timestamp": 1}],
  0,
  0
]''';
