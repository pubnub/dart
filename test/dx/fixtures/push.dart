part of '../push_test.dart';

class FakePubNub implements PubNub {
  List<Invocation> invocations = [];

  FakePubNub();

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}
