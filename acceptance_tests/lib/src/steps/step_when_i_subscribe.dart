import 'dart:convert';

import 'package:gherkin/gherkin.dart';

import '../world.dart';

class StepWhenISubscribe extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I subscribe');

  @override
  Future<void> executeStep() async {
    var subscription =
        world.pubnub.subscribe(channels: {'test'}, keyset: world.keyset);

    subscription.messages.listen((envelope) {
      world.messages.add(envelope);
      world.firstMessageCompleter.complete(envelope);
    }, onError: (exception) {
      world.latestException = exception;
      world.firstMessageCompleter.completeError(exception);
    });
    world.currentSubscription = subscription;

    await subscription.whenStarts;
  }
}
