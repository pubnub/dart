import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/presence.dart';

export '../_endpoints/presence.dart';

final _logger = injectLogger('pubnub.dx.presence');

mixin PresenceDx on Core {
  /// Gets the occupancy information from a list of [channels] and/or [channelGroups].
  ///
  /// If [stateInfo] is `.none`, then it will only return occupancy counts.
  /// If [stateInfo] is `.all`, then it will include each `UUID`s state.
  /// If [stateInfo] is `.onlyUUIDs` (as by default), then it will include `UUID`s without state.
  Future<HereNowResult> hereNow(
      {Keyset? keyset,
      String? using,
      Set<String> channels = const {},
      Set<String> channelGroups = const {},
      StateInfo? stateInfo}) async {
    _logger.info('Here now API call');
    keyset ??= keysets[using];

    Ensure(keyset).isNotNull('keyset');

    var params = HereNowParams(keyset,
        channels: channels, channelGroups: channelGroups, stateInfo: stateInfo);

    _logger.fine(LogEvent(
        message: 'Here now API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<HereNowParams, HereNowResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => HereNowResult.fromJson(object,
            channelName: (channels.length == 1) ? channels.first : null));
  }

  /// Announce in [channels] and [channelGroups] that a device linked to the UUID in the keyset left.
  Future<LeaveResult> announceLeave({
    Keyset? keyset,
    String? using,
    Set<String> channels = const {},
    Set<String> channelGroups = const {},
  }) {
    _logger.info('Announce leave API call');
    keyset ??= keysets[using];

    Ensure(keyset).isNotNull('keyset');

    var params =
        LeaveParams(keyset, channels: channels, channelGroups: channelGroups);

    _logger.fine(LogEvent(
        message: 'Announce leave API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<LeaveParams, LeaveResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => LeaveResult.fromJson(object));
  }

  /// Anounce in [channels] and [channelGroups] that a device linked to the UUID in the keyset is alive.
  Future<HeartbeatResult> announceHeartbeat(
      {Keyset? keyset,
      String? using,
      Set<String> channels = const {},
      Set<String> channelGroups = const {},
      int? heartbeat}) {
    _logger.info('Announce heartbeat API call');
    keyset ??= keysets[using];

    Ensure(keyset).isNotNull('keyset');

    var params = HeartbeatParams(keyset,
        channels: channels, channelGroups: channelGroups, heartbeat: heartbeat);

    _logger.fine(LogEvent(
        message: 'Announce heartbeat API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<HeartbeatParams, HeartbeatResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => HeartbeatResult.fromJson(object));
  }

  Future<GetUserStateResult> getState(
      {Keyset? keyset,
      String? using,
      Set<String> channels = const {},
      Set<String> channelGroups = const {}}) async {
    _logger.info('Get state API call');
    keyset ??= keysets[using];

    Ensure(keyset).isNotNull('keyset');

    var params = GetUserStateParams(keyset,
        channels: channels, channelGroups: channelGroups);

    _logger.fine(LogEvent(
        message: 'Get user state API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<GetUserStateParams, GetUserStateResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => GetUserStateResult.fromJson(object));
  }

  Future<SetUserStateResult> setState(dynamic state,
      {Keyset? keyset,
      String? using,
      Set<String> channels = const {},
      Set<String> channelGroups = const {}}) async {
    _logger.info('Set state API call');
    keyset ??= keysets[using];

    Ensure(keyset).isNotNull('keyset');

    var payload = await parser.encode(state);

    var params = SetUserStateParams(keyset, payload,
        channels: channels, channelGroups: channelGroups);

    _logger.fine(LogEvent(
        message: 'Set user state API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<SetUserStateParams, SetUserStateResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => SetUserStateResult.fromJson(object));
  }
}
