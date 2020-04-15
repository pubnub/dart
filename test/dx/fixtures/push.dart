part of '../push_test.dart';

class FakePubNub implements PubNub {
  List<Invocation> invocations = [];

  FakePubNub();

  @override
  noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}
