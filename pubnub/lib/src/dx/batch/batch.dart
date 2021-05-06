import 'package:pubnub/core.dart';
import 'package:pubnub/src/default.dart';

import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/history.dart';

export 'package:pubnub/src/dx/_endpoints/history.dart'
    show BatchHistoryResult, BatchHistoryResultEntry, CountMessagesResult;

/// Groups common **batch** features together.
///
/// Available as [PubNub.batch].
class BatchDx {
  final Core _core;

  /// @nodoc
  BatchDx(this._core);

  /// Fetch messages for multiple channels using one call.
  ///
  /// If [includeMessageActions] is `true`, then you can only pass in one channel in [channels].
  Future<BatchHistoryResult> fetchMessages(Set<String> channels,
      {Keyset? keyset,
      String? using,
      int? count,
      Timetoken? start,
      Timetoken? end,
      bool? reverse,
      bool? includeMeta,
      bool includeMessageActions = false,
      bool includeMessageType = true,
      bool includeUUID = true}) async {
    keyset ??= _core.keysets[using];

    var SINGLE_CHANNEL_MAX = 100;
    var MULTIPLE_CHANNEL_MAX = 25;
    var max = count;

    if (includeMessageActions == true) {
      Ensure(channels.length).isEqual(1,
          'History can return actions data for a single channel only. Either pass a single channel or disable the includeMessageActions flag.');
    }

    max ??= (channels.length > 1 || includeMessageActions == true)
        ? MULTIPLE_CHANNEL_MAX
        : SINGLE_CHANNEL_MAX;

    var params = BatchHistoryParams(keyset, channels,
        max: max,
        start: start,
        end: end,
        reverse: reverse,
        includeMeta: includeMeta,
        includeMessageActions: includeMessageActions,
        includeMessageType: includeMessageType,
        includeUUID: includeUUID);

    return defaultFlow<BatchHistoryParams, BatchHistoryResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) =>
            BatchHistoryResult.fromJson(object, cipherKey: keyset?.cipherKey));
  }

  /// Get multiple channels' message count using one call.
  ///
  /// [channels] can either be a `Map<String, Timetoken>` or `Set<String>`:
  /// * if you want to count messages in all channels up to a common timetoken, pass in a `Set<String>` and a named parameter [timetoken].
  /// * if you want to specify separate timetoken for each channel, pass in a `Map<String, Timetoken>`.
  ///   Additionally, if a value in the map is null, it will use a timetoken from a named parameter [timetoken].
  Future<CountMessagesResult> countMessages(dynamic channels,
      {Keyset? keyset, String? using, Timetoken? timetoken}) {
    keyset ??= _core.keysets[using];

    var params = CountMessagesParams(keyset);
    if (channels is Set<String>) {
      Ensure(timetoken)
          .isNotNull('When you pass in a Set, timetoken cannot be null.');

      params =
          CountMessagesParams(keyset, channels: channels, timetoken: timetoken);
    } else if (channels is Map<String, Timetoken>) {
      params = CountMessagesParams(keyset,
          channelsTimetoken:
              channels.map((key, value) => MapEntry(key, value)));
    } else {
      Ensure.fail('invalid-type', 'channels',
          ['Set<String>', 'Map<String, Timetoken>']);
    }

    return defaultFlow(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => CountMessagesResult.fromJson(object));
  }
}
