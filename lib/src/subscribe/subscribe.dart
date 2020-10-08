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

  /// Subscribes to [channels] and [channelGroups].
  ///
  /// Returned subscription is automatically resumed.
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

  /// Obtain a [Subscription] to [channels] and [channelGroups].
  ///
  /// You need to manually resume the returned subscription.
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
