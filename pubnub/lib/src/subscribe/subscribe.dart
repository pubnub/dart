import 'package:pubnub/core.dart';

import 'manager.dart';
import 'subscription.dart';

mixin SubscribeDx on Core {
  final Map<Keyset, Manager> _managers = {};

  Manager _getOrCreateManager(Keyset keyset) {
    if (!_managers.containsKey(keyset)) {
      _managers[keyset] = Manager(this, keyset);
    }

    return _managers[keyset];
  }

  /// Returns a set of channels that [uuid] is currently subscribed to.
  Set<String> getSubscribedChannelsForUUID(UUID uuid,
          {bool countPaused = true}) =>
      keysets.keysets
          .where((keyset) => keyset.uuid == uuid)
          .map((keyset) => _managers[keyset])
          .where((manager) => manager != null)
          .expand((manager) => manager.subscriptions)
          .where(
              (sub) => !sub.isCancelled && (countPaused ? !sub.isPaused : true))
          .expand((sub) => sub.channels)
          .toSet();

  /// Returns a set of channel groups that [uuid] is currently subscribed to.
  Set<String> getSubscribedChannelGroupsForUUID(UUID uuid,
          {bool countPaused = true}) =>
      keysets.keysets
          .where((keyset) => keyset.uuid == uuid)
          .map((keyset) => _managers[keyset])
          .where((manager) => manager != null)
          .expand((manager) => manager.subscriptions)
          .where(
              (sub) => !sub.isCancelled && (countPaused ? !sub.isPaused : true))
          .expand((sub) => sub.channelGroups)
          .toSet();

  /// Subscribes to [channels] and [channelGroups].
  ///
  /// Returned subscription is automatically resumed.
  /// Example:
  ///
  /// ```dart
  /// var subscription = await pubnub.subscribe(channels: {'my_test_channel'});
  /// subscription.messages.listen((envelope) {
  ///   // handle envelope
  /// });
  /// ```
  Subscription subscribe(
      {Keyset keyset,
      String using,
      Set<String> channels,
      Set<String> channelGroups,
      bool withPresence}) {
    keyset ??= keysets.obtain(keyset, using);

    var manager = _getOrCreateManager(keyset);

    var subscription = manager.createSubscription(
        channels: channels,
        channelGroups: channelGroups,
        withPresence: withPresence);

    subscription.resume();

    return subscription;
  }

  /// Creates an inactive subscription to [channels] and [channelGroups]. Returns [Subscription].
  ///
  /// You can activate an inactive subscription by calling `subscription.subscribe()`.
  Subscription subscription(
      {Keyset keyset,
      String using,
      Set<String> channels,
      Set<String> channelGroups,
      bool withPresence}) {
    keyset ??= keysets.obtain(keyset, using);

    var manager = _getOrCreateManager(keyset);

    var subscription = manager.createSubscription(
        channels: channels,
        channelGroups: channelGroups,
        withPresence: withPresence);

    subscription.resume();

    return subscription;
  }

  /// Cancels all existing subscriptions.
  Future<void> unsubscribeAll() async {
    for (var manager in _managers.values) {
      await manager.unsubscribeAll();
    }
  }
}
