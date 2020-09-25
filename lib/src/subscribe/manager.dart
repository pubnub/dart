import 'dart:async';

import 'package:pubnub/core.dart';

import 'subscribe_loop/subscribe_loop_state.dart';
import 'subscribe_loop/subscribe_loop.dart';
import 'subscription.dart';
import 'envelope.dart';

/// @nodoc
class Manager {
  final Keyset _keyset;

  final Set<Subscription> _subscriptions = {};

  SubscribeLoop _loop;

  Stream<Envelope> get envelopes => _loop.envelopes;

  Manager(Core core, this._keyset) {
    _loop = SubscribeLoop(core, SubscribeLoopState(_keyset));
  }

  void _updateLoop() {
    var channels = _subscriptions.fold<Set<String>>(
        <String>{},
        (s, sub) => s
          ..addAll({
            ...sub.channels,
            if (sub.withPresence == true) ...sub.presenceChannels
          }));
    var channelGroups = _subscriptions.fold<Set<String>>(
        <String>{},
        (s, sub) => s
          ..addAll({
            ...sub.channelGroups,
            if (sub.withPresence == true) ...sub.presenceChannelGroups
          }));

    _loop.update((state) =>
        state.clone(channels: channels, channelGroups: channelGroups));
  }

  Subscription createSubscription(
      {Set<String> channels, Set<String> channelGroups, bool withPresence}) {
    var subscription =
        Subscription(this, channels, channelGroups, withPresence);

    _subscriptions.add(subscription);

    _updateLoop();

    return subscription;
  }

  Future<void> unsubscribeAll() async {
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}
