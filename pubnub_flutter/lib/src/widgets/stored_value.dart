import 'package:async/async.dart';
import 'package:flutter/widgets.dart';
import 'package:pubnub/pubnub.dart';

import '../provider.dart';
import '../utils/subscription_memory_mixin.dart';
import '../utils/did_init_mixin.dart';

/// Widget that represents a value that is stored in a channel history.
class StoredValue<T> extends StatefulWidget {
  /// The build strategy currently used by this builder.
  ///
  /// This builder must only return a widget and should not have any side effects as it may be called multiple times.
  final StoredValueBuilder<T> builder;

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

  StoredValue(
      {required this.channel,
      required this.builder,
      required this.keyset,
      required this.using,
      this.disableCache = false,
      this.disableHistory = false});

  @override
  _StoredValueState<T> createState() => _StoredValueState<T>();
}

class _StoredValueState<T> extends State<StoredValue<T>>
    with SubscriptionMemory, DidInitState {
  late PubNubProvider provider;
  late Keyset keyset;
  late Stream<T> stream;

  bool get cacheEnabled => provider.cacheEnabled && !widget.disableCache;
  String get cacheKey =>
      '__stored_value_${keyset.subscribeKey}_${widget.channel}';

  @override
  void didInitState() {
    provider = PubNubProvider.of(context);
    keyset = widget.keyset ?? provider.instance.keysets[widget.using];

    var subscription = remember(provider.instance.subscribe(
      channels: {widget.channel},
      keyset: keyset,
    ));

    stream = StreamGroup.mergeBroadcast([
      if (!widget.disableHistory) _fetchLatest().asStream().cast<T>(),
      subscription.messages.map((envelope) => envelope.payload).cast<T>()
    ]);

    if (cacheEnabled) {
      remember(provider.cache.follow(cacheKey, stream));
    }
  }

  @override
  void didUpdateWidget(covariant StoredValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    forget();

    didInitState();
  }

  Future<T?> _fetchLatest() async {
    var result = await provider.instance
        .channel(widget.channel, keyset: keyset)
        .history(chunkSize: 1)
        .more();

    if (result.messages.isEmpty) {
      return null;
    } else {
      return result.messages[0]['message'];
    }
  }

  Future<void> update(T newValue) async {
    await provider.instance
        .channel(widget.channel, keyset: keyset)
        .publish(newValue);
  }

  @override
  void dispose() {
    forget();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: cacheEnabled ? provider.cache.get(cacheKey) : null,
      builder: (context, snapshot) => widget.builder(context, snapshot, update),
    );
  }
}

typedef StoredValueBuilder<T> = Widget Function(BuildContext context,
    AsyncSnapshot<T> snapshot, Future<void> Function(T newValue) update);
