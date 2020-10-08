import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/presence.dart';

export '../_endpoints/presence.dart';

/// @nodoc
extension PresenceKeysetExtension on Keyset {
  /// Presence timeout.
  int get presenceTimeout => settings['#presenceTimeout'];
  set presenceTimeout(int value) => settings['#presenceTimeout'] = value;

  /// Interval at which heartbeats should be sent.
  int get heartbeatInterval => settings['#heartbeatInterval'];
  set heartbeatInterval(int value) => settings['#heartbeatInterval'] = value;

  /// Supress leave events.
  bool get suppressLeaveEvents => settings['#suppressLeaveEvents'];
  set suppressLeaveEvents(bool value) =>
      settings['#suppressLeaveEvents'] = value;
}

mixin PresenceDx on Core {
  /// Gets the occupancy information from a list of [channels] and/or [channelGroups].
  ///
  /// If [stateInfo] is `.none`, then it will only return occupancy counts.
  /// If [stateInfo] is `.all`, then it will include each `UUID`s state.
  /// If [stateInfo] is `.onlyUUIDs` (as by default), then it will include `UUID`s without state.
  Future<HereNowResult> hereNow(
      {Keyset keyset,
      String using,
      Set<String> channels,
      Set<String> channelGroups,
      StateInfo stateInfo}) async {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset).isNotNull('keyset');

    var params = HereNowParams(keyset,
        channels: channels, channelGroups: channelGroups, stateInfo: stateInfo);

    return defaultFlow<HereNowParams, HereNowResult>(
        core: this,
        params: params,
        serialize: (object, [_]) => HereNowResult.fromJson(object,
            channelName: (channels.length == 1) ? channels.first : null));
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
        core: this,
        params: HeartbeatParams(keyset,
            channels: channels,
            channelGroups: channelGroups,
            heartbeat: heartbeat),
        serialize: (object, [_]) => HeartbeatResult.fromJson(object));
  }
}
