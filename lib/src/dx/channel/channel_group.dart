import 'package:logging/logging.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/subscribe/subscription.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'package:pubnub/src/dx/_endpoints/channel_group.dart';

final logger = Logger('pubnub.dx.channel_group');

/// Representation of a channel group.
class ChannelGroup {
  PubNub _core;
  Keyset _keyset;
  String name;

  /// Contains methods that manipulate and get channels in this channel group.
  final ChannelSet channels;

  ChannelGroup(this._core, this._keyset, this.name)
      : channels = ChannelSet(_core, _keyset, name);

  /// Subscribe to this channel group.
  Subscription subscribe({bool withPresence}) => _core.subscribe(
      keyset: _keyset, channelGroups: {name}, withPresence: withPresence);
}

class ChannelSet {
  PubNub _core;
  Keyset _keyset;
  String _name;

  ChannelSet(this._core, this._keyset, this._name);

  /// List all channels in this channel group.
  Future<Set<String>> list() async {
    var result = await _core.channelGroups.listChannels(_name, keyset: _keyset);

    return result.channels;
  }

  /// Add [channels] to this channel group.
  Future<void> add(Set<String> channels) async {
    await _core.channelGroups.addChannels(_name, channels, keyset: _keyset);
  }

  /// Remove [channels] from this channel group.
  Future<void> remove(Set<String> channels) async {
    await _core.channelGroups.removeChannels(_name, channels, keyset: _keyset);
  }
}

class ChannelGroupDx {
  Core _core;

  ChannelGroupDx(this._core);

  /// List all channels in a channel [group].
  Future<ChannelGroupListChannelsResult> listChannels(String group,
      {Keyset keyset, String using}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return defaultFlow<ChannelGroupListChannelsParams,
            ChannelGroupListChannelsResult>(
        log: logger,
        core: _core,
        params: ChannelGroupListChannelsParams(keyset, group),
        serialize: (object, [_]) =>
            ChannelGroupListChannelsResult.fromJson(object));
  }

  /// Add [channels] to the channel [group].
  Future<ChannelGroupChangeChannelsResult> addChannels(
      String group, Set<String> channels,
      {Keyset keyset, String using}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return defaultFlow<ChannelGroupChangeChannelsParams,
            ChannelGroupChangeChannelsResult>(
        log: logger,
        core: _core,
        params: ChannelGroupChangeChannelsParams(keyset, group, add: channels),
        serialize: (object, [_]) =>
            ChannelGroupChangeChannelsResult.fromJson(object));
  }

  /// Remove [channels] from a channel [group].
  Future<ChannelGroupChangeChannelsResult> removeChannels(
      String group, Set<String> channels,
      {Keyset keyset, String using}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return defaultFlow<ChannelGroupChangeChannelsParams,
            ChannelGroupChangeChannelsResult>(
        log: logger,
        core: _core,
        params:
            ChannelGroupChangeChannelsParams(keyset, group, remove: channels),
        serialize: (object, [_]) =>
            ChannelGroupChangeChannelsResult.fromJson(object));
  }

  /// Remove ALL channels from a channel [group].
  Future<ChannelGroupDeleteResult> delete(String group,
      {Keyset keyset, String using}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    return defaultFlow<ChannelGroupDeleteParams, ChannelGroupDeleteResult>(
        log: logger,
        core: _core,
        params: ChannelGroupDeleteParams(keyset, group),
        serialize: (object, [_]) => ChannelGroupDeleteResult.fromJson(object));
  }
}
