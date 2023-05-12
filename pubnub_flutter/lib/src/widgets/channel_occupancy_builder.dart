import 'package:flutter/widgets.dart';
import 'package:pubnub/pubnub.dart';

import '../provider.dart';
import '../utils/did_init_mixin.dart';
import '../utils/subscription_memory_mixin.dart';

/// Widget that builds itself based on the channel occupancy.
///
/// Widget rebuilding is scheduled using [State.setState]. [builder] will be called
/// each time new presence event is received or here now call completes.
///
class ChannelOccupancyBuilder extends StatefulWidget {
  final Subscription subscription;

  final ChannelOccupancyWidgetBuilder builder;

  ChannelOccupancyBuilder({required this.subscription, required this.builder});

  @override
  _ChannelOccupancyBuilderState createState() =>
      _ChannelOccupancyBuilderState();
}

/// Signature for strategies that build widgets based on channel occupancy state.
typedef ChannelOccupancyWidgetBuilder = Widget Function(
    BuildContext, ChannelOccupancySnapshot);

/// Represents current state of channel occupancy.
class ChannelOccupancySnapshot {
  /// Set of [UUID]s representing currently connected users.
  final List<UUID> uuids;

  /// Amount of currently connected users.
  final int occupancy;

  /// @nodoc
  const ChannelOccupancySnapshot._(this.uuids, this.occupancy);
}

class _ChannelOccupancyBuilderState extends State<ChannelOccupancyBuilder>
    with SubscriptionMemory, DidInitState {
  late PubNub pubnub;

  Set<String> uuids = {};
  int occupancy = 0;

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      ChannelOccupancySnapshot._(
          uuids.map((uuid) => UUID(uuid)).toList(), occupancy),
    );
  }

  void _handlePresenceEvent(PresenceEvent event) {
    setState(() {
      occupancy = event.occupancy;

      switch (event.action) {
        case PresenceAction.join:
          uuids.add(event.uuid!.value);
          break;
        case PresenceAction.leave:
        case PresenceAction.timeout:
          uuids.remove(event.uuid!.value);
          break;
        case PresenceAction.stateChange:
          break;
        case PresenceAction.interval:
          uuids.addAll(event.join.map((uuid) => uuid.value));
          uuids.removeAll(event.leave.map((uuid) => uuid.value));
          break;
        case PresenceAction.unknown:
          break;
      }
    });
  }

  void _handleHereNowResult(HereNowResult result) {
    setState(() {
      occupancy = result.totalOccupancy;

      uuids = result.channels.values
          .expand((c) => c.uuids.values)
          .map((info) => info.uuid)
          .toSet();
    });
  }

  @override
  void didUpdateWidget(covariant ChannelOccupancyBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    forget();

    uuids.clear();
    occupancy = 0;

    didInitState();
  }

  @override
  void didInitState() {
    pubnub = PubNubProvider.of(context).instance;

    bind(widget.subscription.presence, _handlePresenceEvent);

    pubnub
        .hereNow(
            channels: widget.subscription.channels,
            channelGroups: widget.subscription.channelGroups)
        .then(_handleHereNowResult);
  }

  @override
  void dispose() {
    forget();

    super.dispose();
  }
}
