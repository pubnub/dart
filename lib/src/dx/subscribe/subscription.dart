import 'dart:async';

import 'package:pubnub/src/core/core.dart';

import 'envelope.dart';
import 'extensions/keyset.dart';

class Subscription {
  final Keyset _keyset;

  /// List of channels that this subscription represents.
  Set<String> channels;

  /// List of channel groups that this subscription represents.
  Set<String> channelGroups;

  /// Indicates if presence is turned on for this subscription.
  final bool withPresence;

  /// A broadcast stream of presence events. Will only emit when [withPresence]
  /// is true.
  Stream<PresenceEvent> presence;

  /// A broadcast stream of messages in this subscription.
  Stream<Envelope> messages;

  /// List of presence channels that this subscription represents.
  ///
  /// If [withPresence] is false, this should be empty.
  Set<String> get presenceChannels => withPresence
      ? channels.map((channel) => '${channel}-pnpres').toSet()
      : {};

  /// List of presence channel groups that this subscription represents.
  ///
  /// If [withPresence] is false, this should be empty.
  Set<String> get presenceChannelGroups => withPresence
      ? channelGroups.map((channelGroup) => '${channelGroup}-pnpres').toSet()
      : {};

  StreamSubscription _streamSubscription;

  Subscription(this.channels, this.channelGroups, this._keyset,
      {this.withPresence});

  /// Resubscribe to [channels] and [channelGroups].
  void subscribe() {
    _keyset.subscriptionManager.update((state) => {
          'channels': state['channels'].union(channels).union(presenceChannels),
          'channelGroups': state['channelGroups']
              .union(channelGroups)
              .union(presenceChannelGroups),
        });

    var s = _keyset.subscriptionManager.messages.where((envelope) {
      return channels.contains(envelope['c']) ||
          channels.contains(envelope['b']) ||
          channelGroups.contains(envelope['b']) ||
          (withPresence &&
              (presenceChannels.contains(envelope['c']) ||
                  presenceChannelGroups.contains(envelope['b'])));
    }).map((envelope) => Envelope.fromJson(envelope));

    var _controller = StreamController<Envelope>.broadcast();

    _streamSubscription = s.listen((env) => _controller.add(env));

    presence = _controller.stream
        .where((envelope) =>
            presenceChannels.contains(envelope.channel) ||
            presenceChannels.contains(envelope.subscriptionPattern) ||
            presenceChannels.contains(envelope.subscriptionPattern))
        .map<PresenceEvent>((envelope) => PresenceEvent.fromEnvelope(envelope));

    messages = _controller.stream.where((envelope) =>
        channels.contains(envelope.channel) ||
        channels.contains(envelope.subscriptionPattern) ||
        channelGroups.contains(envelope.subscriptionPattern));
  }

  /// Unsubscribe from [channels] and [channelGroups].
  Future<void> unsubscribe() async {
    _keyset.subscriptionManager.update((state) => {
          'channels': state['channels']
              .difference(channels)
              .difference(presenceChannels),
          'channelGroups': state['channelGroups']
              .difference(channelGroups)
              .difference(presenceChannelGroups),
        });

    if (_streamSubscription != null) {
      await _streamSubscription.cancel();

      _streamSubscription = null;
    }
  }
}
