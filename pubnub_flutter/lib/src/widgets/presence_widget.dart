import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pubnub/pubnub.dart';

import '../provider.dart';
import '../utils/did_init_mixin.dart';

/// Widget that manages presence of an user.
///
/// This widget couples presence to it's lifecycle.
/// As long as the widget is mounted and [online] is set to  `true`,
/// heartbeats will be sent to the server.
///
/// If [announceLeave] is set to `true`, then leave events will be generated:
/// * when [online] changes from `true` to `false`,
/// * when this widget is unmounted.
///
/// [child] is optional. If `null`, then this widget will be invisible.
///
/// Example:
/// ```dart
/// PresenceWidget(
///   online: true,
///   announceLeave: true,
/// )
/// ```
class PresenceWidget extends StatefulWidget {
  /// Optional child widget for convinience.
  final Widget child;

  /// [Keyset] instance that will be used by this widget.
  final Keyset keyset;

  /// Name of a named keyset that will be used by this widget.
  final String using;

  /// Whether heartbeats should be sent or not.
  final bool online;

  /// Whether leave events should be announced.
  final bool announceLeave;

  /// Amount of time between heartbeats.
  final int heartbeatInterval;

  /// Optional set of channels to override heartbeat channels.
  final Set<String> channels;

  /// Optional set of channel groups to override heartbeat channel groups.
  final Set<String> channelGroups;

  PresenceWidget({
    required this.child,
    required this.keyset,
    required this.using,
    this.online = true,
    this.announceLeave = false,
    this.heartbeatInterval = 200,
    this.channels = const <String>{},
    this.channelGroups = const <String>{},
  });

  @override
  PresenceWidgetState createState() => PresenceWidgetState();
}

class PresenceWidgetState extends State<PresenceWidget> with DidInitState {
  Timer? timer;
  PubNub? _pubnub;

  @override
  void dispose() {
    _cancelTimer();
    _announceLeave();

    super.dispose();
  }

  @override
  void didInitState() {
    _pubnub = PubNubProvider.of(context).instance;

    _setupTimer();
  }

  @override
  void didUpdateWidget(covariant PresenceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    _cancelTimer();

    if (oldWidget.online == true && widget.online == false) {
      _announceLeave();
    }

    if (widget.online) {
      _setupTimer();
    }
  }

  void _cancelTimer() {
    if (timer != null) {
      timer?.cancel();
      timer = null;
    }
  }

  void _setupTimer() {
    if (timer != null) {
      _cancelTimer();
    }

    timer = Timer.periodic(
        Duration(seconds: widget.heartbeatInterval), _sendHeartbeat);
  }

  Future<void> _sendHeartbeat(Timer timer) async {
    var keyset = widget.keyset ?? _pubnub?.keysets[widget.using];

    var channels =
        widget.channels ?? _pubnub?.getSubscribedChannelsForUUID(keyset!.uuid);
    var channelGroups = widget.channelGroups ??
        _pubnub?.getSubscribedChannelGroupsForUUID(keyset!.uuid);

    await _pubnub?.announceHeartbeat(
      heartbeat: widget.heartbeatInterval,
      channels: channels!,
      channelGroups: channelGroups!,
      keyset: widget.keyset,
      using: widget.using,
    );
  }

  Future<void> _announceLeave() async {
    if (widget.announceLeave) {
      var keyset = widget.keyset ?? _pubnub?.keysets[widget.using];

      var channels = widget.channels ??
          _pubnub?.getSubscribedChannelsForUUID(keyset!.uuid);
      var channelGroups = widget.channelGroups ??
          _pubnub?.getSubscribedChannelGroupsForUUID(keyset!.uuid);

      await _pubnub?.announceLeave(
        keyset: widget.keyset,
        using: widget.using,
        channels: channels!,
        channelGroups: channelGroups!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? SizedBox.shrink();
  }
}
