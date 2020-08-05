import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/history.dart';

final _logger = injectLogger('dx.batch.history');

class BatchDx {
  final Core _core;

  BatchDx(this._core);

  /// Fetch messages for multiple channels using one REST call.
  Future<BatchHistoryResult> fetchMessages(Set<String> channels,
      {Keyset keyset,
      String using,
      int count,
      Timetoken start,
      Timetoken end,
      bool reverse,
      bool includeMeta}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);

    return defaultFlow<BatchHistoryParams, BatchHistoryResult>(
        logger: _logger,
        core: _core,
        params: BatchHistoryParams(keyset, channels,
            max: count,
            start: start,
            end: end,
            reverse: reverse,
            includeMeta: includeMeta),
        serialize: (object, [_]) => BatchHistoryResult.fromJson(object,
            cipherKey: keyset.cipherKey,
            decryptFunction: _core.crypto.decrypt));
  }

  /// Get multiple channels' message count using one REST call.
  ///
  /// [channels] can either be a [Map<String, Timetoken>] or [Set<String>]:
  /// * if you want to count messages in all channels up to a common timetoken,
  /// pass in a [Set<String>] and a named parameter [timetoken].
  /// * if you want to specify separate timetoken for each channel,
  /// pass in a [Map<String, Timetoken>]. Additionally, if a value in the map is null,
  /// it will use a timetoken from a named parameter [timetoken].
  Future<CountMessagesResult> countMessages(dynamic channels,
      {Keyset keyset, String using, Timetoken timetoken}) {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);

    CountMessagesParams params;
    if (channels is Set<String>) {
      Ensure(timetoken)
          .isNotNull('When you pass in a Set, timetoken cannot be null.');

      params =
          CountMessagesParams(keyset, channels: channels, timetoken: timetoken);
    } else if (channels is Map<String, Timetoken>) {
      params = CountMessagesParams(keyset,
          channelsTimetoken:
              channels.map((key, value) => MapEntry(key, value ?? timetoken)));
    } else {
      throw InvalidArgumentsException();
    }

    return defaultFlow(
        logger: _logger,
        core: _core,
        params: params,
        serialize: (object, [_]) => CountMessagesResult.fromJson(object));
  }
}
