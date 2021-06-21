import 'dart:async';

import 'package:async/async.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

class Subscriber {
  final PubNub _pn;
  late final Keyset _keyset;
  Subscription? subscription;

  StreamQueue<Envelope>? queue;

  Subscriber.init(this._pn, String subscribeKey, {CipherKey? cipherKey}) {
    _keyset = Keyset(
      subscribeKey: subscribeKey,
      cipherKey: cipherKey,
      uuid: UUID('dart-test-subscriber'),
    );
  }

  void subscribe(String channel) async {
    subscription = _pn.subscribe(keyset: _keyset, channels: {channel});

    queue = StreamQueue(subscription!.messages);
  }

  Subscription? createSubscription(String channel, {Timetoken? timetoken}) {
    subscription = _pn.subscription(channels: {channel}, timetoken: timetoken);
    queue = StreamQueue(subscription!.messages);
    return subscription;
  }

  Future<void> cleanup() async {
    await queue?.cancel(immediate: true);
    return subscription?.cancel();
  }

  Future<void> expectMessage(String channel, String message) {
    var actual = queue?.next;

    return expectLater(
        actual, completion(SubscriptionMessageMatcher(channel, message)));
  }
}

class SubscriptionMessageMatcher extends Matcher {
  final String expectedMessage;
  final String channel;

  SubscriptionMessageMatcher(this.channel, this.expectedMessage);

  @override
  Description describe(Description description) =>
      description.add('matched message data is $expectedMessage');

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    mismatchDescription.add('instead got ${(item as Envelope).payload}');

    return mismatchDescription;
  }

  @override
  bool matches(item, Map matchState) =>
      item.channel == channel && item.payload == expectedMessage;
}
