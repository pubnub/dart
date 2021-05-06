part of '../push_test.dart';

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
