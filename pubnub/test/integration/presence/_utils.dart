import 'dart:async';

import 'package:async/async.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

class PresenceConsumer {
  final PubNub _pubnub;
  late final Keyset _keyset;
  Subscription? subscription;

  StreamQueue<PresenceEvent>? queue;

  PresenceConsumer.setup(this._pubnub, String subscribeKey) {
    _keyset = Keyset(subscribeKey: subscribeKey, uuid: UUID('CONSUMER'));
  }

  void start(String channel, {UUID? fromUUID, bool debug = false}) async {
    subscription = _pubnub.subscribe(
        keyset: _keyset, channels: {channel}, withPresence: true);
    var stream = subscription!.presence;

    if (debug) {
      subscription!.presence.listen((event) {
        print(
            'EVENT: ${event.action}, ${event.uuid} (${event.timetoken}) ${event.envelope.originalMessage}');
      });
    }

    if (fromUUID != null) {
      stream = subscription!.presence.where((event) => event.uuid == fromUUID);
    }

    queue = StreamQueue(stream);
  }

  Future<void> end() async {
    await queue?.cancel(immediate: true);
    return subscription?.cancel();
  }

  Future<void> expectEvent(
      {required PresenceAction action, required UUID uuid, Duration? within}) {
    var future = queue!.next;

    if (within != null) {
      future = Future.any([
        future,
        Future.delayed(
            within,
            () => Future.error(TimeoutException(
                'Expectation wasn\'t fullfilled within ${within.inSeconds} seconds'))),
      ]);
    }

    return expectLater(
        future,
        completion(PresenceEventMatcher(
          expectedAction: action,
          expectedUUID: uuid,
        )));
  }
}

class PresenceEventMatcher extends Matcher {
  final PresenceAction expectedAction;
  final UUID expectedUUID;

  PresenceEventMatcher(
      {required this.expectedAction, required this.expectedUUID});

  @override
  Description describe(Description description) =>
      description.add('matches event action $expectedAction');

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    mismatchDescription.add('instead got ${item.action}');

    return mismatchDescription;
  }

  @override
  bool matches(item, Map matchState) {
    if (item is PresenceEvent) {
      return item.action == expectedAction && item.uuid == expectedUUID;
    } else {
      return false;
    }
  }
}
