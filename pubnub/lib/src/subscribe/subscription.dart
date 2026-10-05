import 'dart:async';

import 'package:pubnub/core.dart';

import 'manager.dart';
import 'envelope.dart';
import 'events.dart';

final _logger = injectLogger('pubnub.subscription');

/// Represents a subscription to a set of channels and channel groups.
///
/// Immutable. Can be paused and resumed multiple times.
/// After [cancel] is called, the subscription cannot be used again.
class Subscription {
  final Manager _manager;
  final bool? _withPresence;
  final Set<String>? _channels;
  final Set<String>? _channelGroups;
  final String? _projection;

  /// Keyset that this subscription is using.
  Keyset get keyset => _manager.keyset;

  /// Whether this subscription receives presence events.
  bool get withPresence => _withPresence ?? false;

  /// DataSync projection observed by this subscription, `null` for the base
  /// projection.
  String? get projection => _projection;

  /// Set of channels that this subscription represents.
  ///
  /// When [projection] is set, these are the projection data channels
  /// `__{projection}__{id}` of the requested channels.
  Set<String> get channels => {..._channels ?? <String>{}};

  /// Set of channel groups that this subscription represents.
  Set<String> get channelGroups => {..._channelGroups ?? <String>{}};

  /// Completes when a subscription actually starts listening for messages.
  ///
  /// - This Future will be rebuilt each subscription loop.
  /// - If current subscription loop fails, this future will complete with an exception.
  /// - Each Future retrieved with this getter is guaranteed to complete before the next subscribe loop request starts.
  Future<void> get whenStarts => _manager.whenStarts;

  /// Whether this subscription has been cancelled.
  bool get isCancelled => _cancelCompleter.isCompleted;

  /// Whether this subscription is currently paused.
  bool get isPaused => _envelopeSubscription == null;

  /// Set of presence channels that are generated from set of channels
  Set<String> get presenceChannels =>
      channels.map((channel) => '$channel-pnpres').toSet();

  /// Set of presence channel groups that are generated from set of channel groups
  Set<String> get presenceChannelGroups =>
      channelGroups.map((channelGroup) => '$channelGroup-pnpres').toSet();

  /// Broadcast stream of all events in this subscription.
  ///
  /// Each kind of event has its own [SubscriptionEvent] subtype, so the
  /// events can be handled with an exhaustive `switch`. Events of a type that
  /// is not recognized by the SDK are discarded.
  Stream<SubscriptionEvent> get events => _eventsController.stream;

  /// Broadcast stream of messages published to the channels of this subscription.
  ///
  /// Signals, message actions, files, objects and DataSync events are emitted
  /// on [signals], [messageActions], [files], [objects] and [dataSync].
  Stream<Envelope> get messages =>
      _eventsOfType<MessageEvent>().map((event) => event.envelope);

  /// Broadcast stream of presence events.
  ///
  /// Will only emit when [withPresence] is true.
  Stream<PresenceEvent> get presence => _eventsOfType<PresenceEvent>();

  /// Broadcast stream of signals.
  Stream<SignalEvent> get signals => _eventsOfType<SignalEvent>();

  /// Broadcast stream of message actions being added or removed.
  Stream<MessageActionEvent> get messageActions =>
      _eventsOfType<MessageActionEvent>();

  /// Broadcast stream of shared files.
  Stream<FileEvent> get files => _eventsOfType<FileEvent>();

  /// Broadcast stream of App Context (objects) changes.
  Stream<ObjectsEvent> get objects => _eventsOfType<ObjectsEvent>();

  /// Broadcast stream of DataSync changes.
  Stream<DataSyncEvent> get dataSync => _eventsOfType<DataSyncEvent>();

  Stream<T> _eventsOfType<T extends SubscriptionEvent>() =>
      _eventsController.stream.where((event) => event is T).cast<T>();

  final Completer<void> _cancelCompleter = Completer();

  final StreamController<SubscriptionEvent> _eventsController =
      StreamController.broadcast();

  StreamSubscription<SubscriptionEvent>? _envelopeSubscription;

  final Set<dynamic> _reportedUnknownTypes = {};

  Subscription(
      this._manager, this._channels, this._channelGroups, this._withPresence,
      {String? projection})
      : _projection = projection;

  /// Resume currently paused subscription.
  ///
  /// If subscription is not paused, then this method is a no-op.
  void resume() {
    if (isCancelled) {
      _logger
          .warning('Tried resuming a subscription that is already cancelled.');
      return;
    }

    if (!isPaused) {
      _logger.silly('Resuming a subscription that is not paused is a no-op.');
      return;
    }

    _logger.verbose('Resuming subscription.');

    _envelopeSubscription = _manager.envelopes
        .where((envelope) {
          // If message was sent to one of our channels.
          if (channels.contains(envelope.channel)) {
            return true;
          }

          // If message was sent to one of our channel patterns.
          if (channels.contains(envelope.subscriptionPattern)) {
            return true;
          }

          // If message was sent to one of our channel groups.
          if (channelGroups.contains(envelope.subscriptionPattern)) {
            return true;
          }

          // If presence is enabled...

          if (withPresence) {
            // ...and message was sent to one of our presence channels.
            if (presenceChannels.contains(envelope.channel)) {
              return true;
            }

            // ...and message was sent to one of our presence channel groups.
            if (presenceChannelGroups.contains(envelope.subscriptionPattern)) {
              return true;
            }
          }

          // Otherwise this is not our message.
          return false;
        })
        .map(_toEvent)
        .where((event) => event != null)
        .cast<SubscriptionEvent>()
        .listen(
          _eventsController.add,
          onError: (error) {
            _eventsController.addError(error);
          },
        );
  }

  SubscriptionEvent? _toEvent(Envelope envelope) {
    var event = SubscriptionEvent.fromEnvelope(envelope, keyset);

    if (event == null) {
      var type = envelope.originalMessage['e'];
      if (_reportedUnknownTypes.add(type)) {
        _logger.warning(
            'Discarding events of unrecognized or malformed type (e: $type).');
      }
      _logger
          .silly('Discarded event on channel ${envelope.channel} (e: $type).');
    }

    return event;
  }

  /// Pause subscription.
  ///
  /// Pausing subscription will prevent all streams of this subscription from emitting events.
  /// Keep in mind that you may miss messages while subscription is paused.
  /// If subscription is currently paused, this method is a no-op.
  void pause() {
    if (isCancelled) {
      _logger
          .warning('Tried to pause a subscription that is already cancelled.');
      return;
    }

    if (isPaused) {
      _logger
          .silly('Pausing a subscription that is already paused is a no-op.');
      return;
    }

    _logger.info('Pausing subscription.');

    _envelopeSubscription?.cancel();
    _envelopeSubscription = null;
  }

  /// Cancels the subscription.
  ///
  /// This disposes internal streams, so the subscription becomes unusable.
  Future<void> cancel() async {
    if (isCancelled) {
      _logger.warning(
          'Tried cancelling a subscription that is already cancelled.');
      return;
    }

    _logger.verbose('Subscription cancelled.');

    await _envelopeSubscription?.cancel();
    await _eventsController.close();

    _cancelCompleter.complete();

    _manager.removeSubscription(this);
  }

  /// Alias for [cancel].
  Future<void> dispose() => cancel();

  /// Alias for [resume].
  void subscribe() {
    if (!isPaused || isCancelled) {
      _manager
          .reconnect(); // Reconnect the subscription, when not intentionally paused.
    } else {
      resume(); // Resume the subscription, which was intentionally paused.
    }
  }

  /// Alias for [pause].
  void unsubscribe() => pause();

  /// Restores the subscription and its shared, underlying subscribe loop after an exception.
  Future<void> restore() async {
    await _manager.restore();
  }
}
