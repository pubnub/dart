import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:pubnub/pubnub.dart';

import '../provider.dart';
import '../cache.dart';
import '../utils/did_init_mixin.dart';
import '../utils/subscription_memory_mixin.dart';

/// Widget that builds itself based on the interaction with a channel.
///
/// Widget rebuilding is scheduled using [State.setState]. [builder] will be called
/// each time new message is received from subscription or when history state changes.
///
/// Messages are received from three sources that can be separately disabled:
/// * subscription which receives new messages sent after widget creation (disable setting [disableSubscription] to `true`),
/// * history which receives old messages using Storage and Playback feature (disable setting [disableHistory] to `true`),
/// * cache which uses [Cache] passed into [PubNubProvider.cache] (disable setting [disableCache] to `true`).
///
class ChannelBuilder extends StatefulWidget {
  /// The build strategy currently used by this builder.
  ///
  /// This builder must only return a widget and should not have any side effects as it may be called multiple times.
  final ChannelWidgetBuilder builder;

  /// Channel that this widget will operate on.
  final String channel;

  /// [Keyset] instance that will be used by this widget.
  final Keyset keyset;

  /// Name of a named keyset that will be used by this widget.
  final String using;

  /// Disable history fetching. Defaults to false.
  final bool disableHistory;

  /// Disable caching. Defaults to false.
  ///
  /// If cache has not been passed to the [PubNubProvider], caching will be disabled.
  final bool disableCache;

  /// Disable subscription. Defaults to false.
  final bool disableSubscription;

  /// Whether subscription should be receiving presence updates.
  final bool withPresence;

  ChannelBuilder({
    required this.channel,
    required this.builder,
    required this.keyset,
    required this.using,
    this.disableCache = false,
    this.disableHistory = false,
    this.disableSubscription = false,
    this.withPresence = false,
  });

  @override
  _ChannelBuilderState createState() => _ChannelBuilderState();
}

enum ChannelMessageSource { subscription, history, cache }

/// Describes a message received on a channel.
class ChannelMessage extends BaseMessage {
  /// Source of the message.
  final ChannelMessageSource source;

  const ChannelMessage(Timetoken publishedAt, dynamic content,
      dynamic originalMessage, this.source)
      : super(
          content: content,
          publishedAt: publishedAt,
          originalMessage: originalMessage,
        );
}

/// Describes actions and current state of a channel.
class ChannelSnapshot {
  final _ChannelBuilderState _state;

  /// List of messages.
  final List<ChannelMessage> messages;

  /// Whether history is currently fetching more messages.
  final bool isFetching;

  /// @nodoc
  ChannelSnapshot._(this._state)
      : messages = List.unmodifiable(_state.messages),
        isFetching = _state.isFetching;

  /// Subscription used to get the latest messages.
  Subscription get subscription => _state.subscription;

  /// Fetches more messages from the history.
  Future<void> more() async {
    await _state.fetchMore();
  }
}

class _ChannelBuilderState extends State<ChannelBuilder>
    with SubscriptionMemory, DidInitState {
  late PubNubProvider provider;
  late Keyset keyset;

  bool get cacheEnabled => provider.cacheEnabled && !widget.disableCache;
  String get cacheKey =>
      '__channel_view_${keyset.subscribeKey}_${widget.channel}';

  final List<ChannelMessage> localMessages = [];
  List<ChannelMessage> cachedMessages = [];

  late PaginatedChannelHistory history;
  late Subscription subscription;

  List<ChannelMessage> get messages => [
        if (cacheEnabled && history.messages.isEmpty) ...cachedMessages,
        if (!widget.disableSubscription) ...localMessages,
        if (!widget.disableHistory)
          ...history.messages.map((msg) => ChannelMessage(msg.publishedAt,
              msg.content, msg.originalMessage, ChannelMessageSource.history)),
      ]..sort((a, b) => (b.publishedAt.value - a.publishedAt.value).toInt());

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, ChannelSnapshot._(this));
  }

  @override
  void didInitState() {
    provider = PubNubProvider.of(context);
    keyset = widget.keyset ?? provider.instance.keysets[widget.using];

    if (cacheEnabled) {
      var messages = provider.cache.get<List<dynamic>>(cacheKey) ?? [];

      cachedMessages = messages
          .map((msg) => ChannelMessage(Timetoken(msg['timetoken']),
              msg['contents'], msg, ChannelMessageSource.cache))
          .toList();
    }

    if (!widget.disableSubscription) {
      subscription = remember(provider.instance.subscribe(
          channels: {widget.channel}, withPresence: widget.withPresence));

      bind<Envelope>(subscription.messages, (envelope) {
        localMessages.add(ChannelMessage(envelope.publishedAt, envelope.payload,
            envelope.originalMessage, ChannelMessageSource.subscription));

        cacheMessages();
      });
    }

    if (!widget.disableHistory) {
      history = provider.instance.channel(widget.channel).history(
            chunkSize: min(
              max(cachedMessages.isEmpty ? 10 : cachedMessages.length, 10),
              100,
            ),
          );

      fetchMore();
    }
  }

  @override
  void didUpdateWidget(covariant ChannelBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    forget();

    localMessages.clear();
    cachedMessages.clear();

    didInitState();
  }

  @override
  void dispose() {
    forget();

    super.dispose();
  }

  bool isFetching = false;

  Future<void> fetchMore() async {
    if (!widget.disableHistory && history.hasMore && !isFetching) {
      setState(() {
        isFetching = true;
      });

      await history.more();

      cacheMessages();

      setState(() {
        isFetching = false;
      });
    }
  }

  void cacheMessages() {
    if (cacheEnabled) {
      var preparedMessages = messages
          .map(
            (msg) => <String, dynamic>{
              'timetoken': msg.publishedAt.value,
              'contents': msg.content
            },
          )
          .toList();

      provider.cache.set(cacheKey, preparedMessages);
    }
  }
}

/// Signature for strategies that build widgets based on channel state.
typedef ChannelWidgetBuilder = Widget Function(BuildContext, ChannelSnapshot);
