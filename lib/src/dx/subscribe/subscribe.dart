import 'package:logging/logging.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'extensions/keyset.dart';
import 'subscription.dart';
import 'manager/manager.dart';

import 'package:pubnub/src/dx/_endpoints/presence.dart';

export 'extensions/keyset.dart';

final _log = Logger('pubnub.dx.subscribe');

mixin SubscribeDx on Core {
  /// Subscribes to [channels] and [channelGroups]. Returns [Subscription].
  Subscription subscribe(
      {Keyset keyset,
      String using,
      Set<String> channels,
      Set<String> channelGroups,
      bool withPresence}) {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    if (keyset.subscriptionManager == null) {
      keyset.subscriptionManager = SubscriptionManager(this, keyset);
      keyset.subscriptionManager.update((state) => {#isEnabled: true});
    }

    var subscription = Subscription(channels ?? {}, channelGroups ?? {}, keyset,
        withPresence: withPresence ?? false);

    subscription.subscribe();
    keyset.addSubscription(subscription);

    return subscription;
  }

  /// Unsubscribes from all channels and channel groups.
  void unsubscribeAll() async {
    super.keysets.forEach((key, value) async {
      for (var sub in value.subscriptions) {
        await sub.unsubscribe();
      }
    });
  }

  /// Announce in [channels] and [channelGroups] that a device linked to the UUID in the keyset left.
  Future<LeaveResult> announceLeave({
    Keyset keyset,
    String using,
    Set<String> channels,
    Set<String> channelGroups,
  }) {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset).isNotNull('keyset');

    return defaultFlow<LeaveParams, LeaveResult>(
        log: _log,
        core: this,
        params: LeaveParams(keyset,
            channels: channels, channelGroups: channelGroups),
        serialize: (object, [_]) => LeaveResult.fromJson(object));
  }

  /// Anounce in [channels] and [channelGroups] that a device linked to the UUID in the keyset is alive.
  Future<HeartbeatResult> announceHeartbeat(
      {Keyset keyset,
      String using,
      Set<String> channels,
      Set<String> channelGroups,
      int heartbeat}) {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset).isNotNull('keyset');

    return defaultFlow<HeartbeatParams, HeartbeatResult>(
        log: _log,
        core: this,
        params: HeartbeatParams(keyset,
            channels: channels,
            channelGroups: channelGroups,
            heartbeat: heartbeat),
        serialize: (object, [_]) => HeartbeatResult.fromJson(object));
  }
}
