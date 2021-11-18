import 'dart:async';

import 'package:pubnub/core.dart';

import 'subscribe_loop/subscribe_loop_state.dart';
import 'subscribe_loop/subscribe_loop.dart';
import 'subscription.dart';
import 'envelope.dart';

/// @nodoc
class Manager {
  final Keyset keyset;
  final Set<Subscription> subscriptions = {};
  late final SubscribeLoop _loop;

  Stream<Envelope> get envelopes => _loop.envelopes;

  Future<void> get whenStarts => _loop.whenStarts;

  Manager(Core core, this.keyset) {
    _loop = SubscribeLoop(core, SubscribeLoopState(keyset));
  }

  void _updateLoop({bool skipCancel = false, Timetoken? customTimetoken}) {
    var channels = subscriptions.fold<Set<String>>(
        <String>{},
        (s, sub) => s
          ..addAll(<String>{
            ...sub.channels,
            if (sub.withPresence == true) ...sub.presenceChannels
          }));
    var channelGroups = subscriptions.fold<Set<String>>(
        <String>{},
        (s, sub) => s
          ..addAll(<String>{
            ...sub.channelGroups,
            if (sub.withPresence == true) ...sub.presenceChannelGroups
          }));

    _loop.update(
        (state) => state.clone(
            timetoken: Timetoken(BigInt.zero),
            customTimetoken: customTimetoken,
            channels: channels,
            channelGroups: channelGroups),
        skipCancel: skipCancel);
  }

  Subscription createSubscription(
      {Set<String>? channels,
      Set<String>? channelGroups,
      bool? withPresence,
      Timetoken? timetoken}) {
    var subscription =
        Subscription(this, channels, channelGroups, withPresence);

    subscriptions.add(subscription);

    _updateLoop(customTimetoken: timetoken);

    return subscription;
  }

  void removeSubscription(Subscription subscription) {
    subscriptions.remove(subscription);

    _updateLoop(skipCancel: true);
  }

  Future<void> unsubscribeAll() async {
    for (var subscription in subscriptions.toList()) {
      await subscription.cancel();
    }
  }

  Future<void> restore() async {
    _loop.update((state) => state.clone(isErrored: false), skipCancel: false);
  }
}
