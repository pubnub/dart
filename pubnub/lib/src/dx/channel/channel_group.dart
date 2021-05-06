import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/channel_group.dart';

export '../_endpoints/channel_group.dart';

/// Groups **channel group** methods together.
class ChannelGroupDx {
  final Core _core;

  /// @nodoc
  ChannelGroupDx(this._core);

  /// Lists all channels in a channel [group].
  Future<ChannelGroupListChannelsResult> listChannels(String group,
      {Keyset? keyset, String? using}) {
    keyset ??= _core.keysets[using];
    return defaultFlow<ChannelGroupListChannelsParams,
            ChannelGroupListChannelsResult>(
        keyset: keyset,
        core: _core,
        params: ChannelGroupListChannelsParams(keyset, group),
        serialize: (object, [_]) =>
            ChannelGroupListChannelsResult.fromJson(object));
  }

  /// Adds [channels] to the channel [group].
  Future<ChannelGroupChangeChannelsResult> addChannels(
      String group, Set<String> channels,
      {Keyset? keyset, String? using}) {
    keyset ??= _core.keysets[using];
    return defaultFlow<ChannelGroupChangeChannelsParams,
            ChannelGroupChangeChannelsResult>(
        keyset: keyset,
        core: _core,
        params: ChannelGroupChangeChannelsParams(keyset, group, add: channels),
        serialize: (object, [_]) =>
            ChannelGroupChangeChannelsResult.fromJson(object));
  }

  /// Removes [channels] from a channel [group].
  Future<ChannelGroupChangeChannelsResult> removeChannels(
      String group, Set<String> channels,
      {Keyset? keyset, String? using}) {
    keyset ??= _core.keysets[using];
    return defaultFlow<ChannelGroupChangeChannelsParams,
            ChannelGroupChangeChannelsResult>(
        keyset: keyset,
        core: _core,
        params:
            ChannelGroupChangeChannelsParams(keyset, group, remove: channels),
        serialize: (object, [_]) =>
            ChannelGroupChangeChannelsResult.fromJson(object));
  }

  /// Removes ALL channels from a channel [group].
  Future<ChannelGroupDeleteResult> delete(String group,
      {Keyset? keyset, String? using}) {
    keyset ??= _core.keysets[using];
    return defaultFlow<ChannelGroupDeleteParams, ChannelGroupDeleteResult>(
        keyset: keyset,
        core: _core,
        params: ChannelGroupDeleteParams(keyset, group),
        serialize: (object, [_]) => ChannelGroupDeleteResult.fromJson(object));
  }
}
