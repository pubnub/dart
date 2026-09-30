import 'package:pubnub/core.dart';

import 'manager.dart';
import 'subscription.dart';

final _logger = injectLogger('pubnub.dx.subscribe');

mixin SubscribeDx on Core {
  final Map<Keyset, Manager> _managers = {};

  Manager _getOrCreateManager(Keyset keyset) {
    if (!_managers.containsKey(keyset)) {
      _managers[keyset] = Manager(this, keyset);
    }

    return _managers[keyset]!;
  }

  /// Returns a set of channels that [uuid] is currently subscribed to.
  Set<String> getSubscribedChannelsForUUID(UUID uuid,
          {bool countPaused = true}) =>
      keysets.keysets
          .where((keyset) => keyset.uuid == uuid)
          .map((keyset) => _managers[keyset])
          .where((manager) => manager != null)
          .cast<Manager>()
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
          .cast<Manager>()
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
  /// var subscription = pubnub.subscribe(channels: {'my_test_channel'});
  /// subscription.messages.listen((envelope) {
  ///   // handle published message
  /// });
  /// subscription.signals.listen((signal) {
  ///   // handle signal
  /// });
  /// ```
  ///
  /// Other kinds of events are emitted on [Subscription.messageActions],
  /// [Subscription.files], [Subscription.objects], [Subscription.dataSync]
  /// and [Subscription.presence], or all of them together on
  /// [Subscription.events]:
  ///
  /// ```dart
  /// subscription.events.listen((event) {
  ///   switch (event) {
  ///     case MessageEvent(:final message):
  ///       print('message: $message');
  ///     case FileEvent(:final file):
  ///       print('file: ${file?.name}');
  ///     default:
  ///   }
  /// });
  /// ```
  Subscription subscribe(
      {Set<String>? channels,
      Set<String>? channelGroups,
      bool withPresence = false,
      Keyset? keyset,
      String? using,
      Timetoken? timetoken}) {
    _logger.info('Subscribe API call');
    keyset ??= keysets[using];

    _logger.fine(LogEvent(
        message: 'Subscribe API call with parameters:',
        details: {
          'channels': channels,
          'channelGroups': channelGroups,
          'withPresence': withPresence,
          'timetoken': timetoken,
        },
        detailsType: LogEventDetailsType.apiParametersInfo));

    var manager = _getOrCreateManager(keyset);

    var subscription = manager.createSubscription(
        channels: channels,
        channelGroups: channelGroups,
        withPresence: withPresence,
        timetoken: timetoken);

    subscription.resume();

    return subscription;
  }

  /// Creates an inactive subscription to [channels] and [channelGroups]. Returns [Subscription].
  ///
  /// You can activate an inactive subscription by calling `subscription.subscribe()`.
  Subscription subscription(
      {Set<String>? channels,
      Set<String>? channelGroups,
      bool withPresence = false,
      Keyset? keyset,
      String? using,
      Timetoken? timetoken}) {
    keyset ??= keysets[using];

    var manager = _getOrCreateManager(keyset);

    var subscription = manager.createSubscription(
        channels: channels,
        channelGroups: channelGroups,
        withPresence: withPresence,
        timetoken: timetoken);

    return subscription;
  }

  /// Cancels all existing subscriptions.
  Future<void> unsubscribeAll() async {
    _logger.info('Unsubscribing all subscriptions.');
    for (var manager in _managers.values) {
      await manager.unsubscribeAll();
    }
  }
}
