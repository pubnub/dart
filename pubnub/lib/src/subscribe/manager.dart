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

  SubscribeLoop _loop;

  Stream<Envelope> get envelopes => _loop.envelopes;

  Manager(Core core, this.keyset) {
    _loop = SubscribeLoop(core, SubscribeLoopState(keyset));
  }

  void _updateLoop() {
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

    _loop.update((state) =>
        state.clone(channels: channels, channelGroups: channelGroups));
  }

  Subscription createSubscription(
      {Set<String> channels,
      Set<String> channelGroups,
      bool withPresence = false}) {
    var subscription =
        Subscription(this, channels, channelGroups, withPresence);

    subscriptions.add(subscription);

    _updateLoop();

    return subscription;
  }

  Future<void> unsubscribeAll() async {
    for (var subscription in subscriptions) {
      await subscription.cancel();
    }
  }
}
