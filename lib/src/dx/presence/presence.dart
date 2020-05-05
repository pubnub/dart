import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_endpoints/presence.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

export '../_endpoints/presence.dart' show StateInfo;

final _logger = injectLogger('dx.presence');

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
        logger: _logger,
        core: this,
        params: params,
        serialize: (object, [_]) => HereNowResult.fromJson(object,
            channelName: (channels.length == 1) ? channels.first : null));
  }
}
