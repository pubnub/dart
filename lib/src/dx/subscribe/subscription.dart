import 'dart:async';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/disposable.dart';

import 'envelope.dart';
import 'extensions/keyset.dart';

final _logger = injectLogger('dx.subscribe.subscription');

class Subscription extends Disposable {
  final Core _core;
  final Keyset _keyset;

  /// List of channels that this subscription represents.
  Set<String> channels;

  /// List of channel groups that this subscription represents.
  Set<String> channelGroups;

  /// Indicates if presence is turned on for this subscription.
  final bool withPresence;

  /// A broadcast stream of presence events. Will only emit when [withPresence]
  /// is true.
  Stream<PresenceEvent> get presence => _streamController.stream
      .where((envelope) =>
          presenceChannels.contains(envelope.channel) ||
          presenceChannels.contains(envelope.subscriptionPattern) ||
          presenceChannels.contains(envelope.subscriptionPattern))
      .map<PresenceEvent>((envelope) => PresenceEvent.fromEnvelope(envelope));

  /// A broadcast stream of messages in this subscription.
  Stream<Envelope> get messages => _streamController.stream.where((envelope) =>
      channels.contains(envelope.channel) ||
      channels.contains(envelope.subscriptionPattern) ||
      channelGroups.contains(envelope.subscriptionPattern));

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

  final StreamController _streamController =
      StreamController<Envelope>.broadcast();

  Subscription(this.channels, this.channelGroups, this._core, this._keyset,
      {this.withPresence});

  /// Resubscribe to [channels] and [channelGroups].
  Future<void> subscribe() async {
    if (isDisposed) {
      _logger.warning('Tried subscribing to a disposed subscription...');
      return;
    }

    if (_streamSubscription == null) {
      _logger.info('Subscribing to the stream...');
      _keyset.addSubscription(this);

      await _keyset.subscriptionManager.update((state) => {
            'channels':
                state['channels'].union(channels).union(presenceChannels),
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
      }).asyncMap((envelope) async {
        if ((envelope['e'] == null || envelope['e'] == 4) &&
            !envelope['b'].endsWith('-pnpres') &&
            _keyset.cipherKey != null) {
          envelope['d'] = await _core.parser
              .decode(_core.crypto.decrypt(_keyset.cipherKey, envelope['d']));
        }
        return Envelope.fromJson(envelope);
      });
      _streamSubscription = s.listen((env) => _streamController.add(env));
    }
  }

  /// Unsubscribe from [channels] and [channelGroups].
  Future<void> unsubscribe() async {
    if (isDisposed) {
      _logger.warning('Tried unsubscribing from a disposed subscription...');
      return;
    }

    if (_streamSubscription != null) {
      _logger.info('Unsubscribing from the stream...');
      _keyset.removeSubscription(this);

      await _keyset.subscriptionManager.update((state) => {
            'channels': state['channels']
                .difference(channels)
                .difference(presenceChannels),
            'channelGroups': state['channelGroups']
                .difference(channelGroups)
                .difference(presenceChannelGroups),
          });

      await _streamSubscription.cancel();

      _streamSubscription = null;
    } else {
      _logger.warning('Tried unsubscribing from an inactive stream...');
    }
  }

  final Completer<void> _didDispose = Completer();
  @override
  Future<void> get didDispose => _didDispose.future;

  bool _isDisposed = false;

  /// Whether this subscription is disposed.
  ///
  /// After a [Subscription] is disposed, you cannot resubscribe to it.
  @override
  bool get isDisposed => _isDisposed;

  /// Dispose of this subscription.
  ///
  /// If it's still subscribed, it will unsubscribe first.
  ///
  /// After disposing, you cannot use a subscription anymore.
  @override
  Future<void> dispose() async {
    _keyset.removeSubscription(this);

    await unsubscribe();

    await _streamController.close();

    _logger.verbose('Disposed Subscription.');
    _isDisposed = true;
    _didDispose.complete();
  }
}
