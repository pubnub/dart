part of '../channel_test.dart';

class FakePubNub implements PubNub {
  List<Invocation> invocations = [];
  Map<Symbol, dynamic> results = {};

  FakePubNub();

  void returnWhen(Symbol name, dynamic result) {
    results[name] = result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    invocations.add(invocation);

    if (results.containsKey(invocation.memberName)) {
      var result = results[invocation.memberName]!;

      results.remove(invocation.memberName);

      return result;
    }
  }
}

final _historyMoreSuccessResponse = '''[
  [{"message":42, "timetoken": 1}],
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
  [{"message":42, "timetoken": 1}],
  0,
  0
]''';
