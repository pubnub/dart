import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/channel_group.dart';

export '../_endpoints/channel_group.dart';

final _logger = injectLogger('pubnub.dx.channel_group');

/// Groups **channel group** methods together.
class ChannelGroupDx {
  final Core _core;

  /// @nodoc
  ChannelGroupDx(this._core);

  /// Lists all channels in a channel [group].
  Future<ChannelGroupListChannelsResult> listChannels(String group,
      {Keyset? keyset, String? using}) {
    _logger.silly('List channels API call');
    keyset ??= _core.keysets[using];

    var params = ChannelGroupListChannelsParams(keyset, group);

    _logger.fine(LogEvent(
        message: 'List channel group channels API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<ChannelGroupListChannelsParams,
            ChannelGroupListChannelsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) =>
            ChannelGroupListChannelsResult.fromJson(object));
  }

  /// Adds [channels] to the channel [group].
  Future<ChannelGroupChangeChannelsResult> addChannels(
      String group, Set<String> channels,
      {Keyset? keyset, String? using}) {
    _logger.silly('Add channels API call');
    keyset ??= _core.keysets[using];

    var params = ChannelGroupChangeChannelsParams(keyset, group, add: channels);

    _logger.fine(LogEvent(
        message: 'Add channels to channel group API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<ChannelGroupChangeChannelsParams,
            ChannelGroupChangeChannelsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) =>
            ChannelGroupChangeChannelsResult.fromJson(object));
  }

  /// Removes [channels] from a channel [group].
  Future<ChannelGroupChangeChannelsResult> removeChannels(
      String group, Set<String> channels,
      {Keyset? keyset, String? using}) {
    _logger.silly('Remove channels API call');
    keyset ??= _core.keysets[using];

    var params =
        ChannelGroupChangeChannelsParams(keyset, group, remove: channels);

    _logger.fine(LogEvent(
        message: 'Remove channels from channel group API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<ChannelGroupChangeChannelsParams,
            ChannelGroupChangeChannelsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) =>
            ChannelGroupChangeChannelsResult.fromJson(object));
  }

  /// Removes ALL channels from a channel [group].
  Future<ChannelGroupDeleteResult> delete(String group,
      {Keyset? keyset, String? using}) {
    _logger.silly('Delete channel group API call');
    keyset ??= _core.keysets[using];

    var params = ChannelGroupDeleteParams(keyset, group);

    _logger.fine(LogEvent(
        message: 'Delete channel group API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<ChannelGroupDeleteParams, ChannelGroupDeleteResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => ChannelGroupDeleteResult.fromJson(object));
  }
}
