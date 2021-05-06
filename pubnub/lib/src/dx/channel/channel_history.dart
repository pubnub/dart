import 'package:pubnub/core.dart';
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/history.dart';

import 'channel.dart';

/// Order of messages based on timetoken.
enum ChannelHistoryOrder { ascending, descending }

/// @nodoc
extension ChannelHistoryOrderExtension on ChannelHistoryOrder {
  T choose<T>({required T ascending, required T descending}) {
    switch (this) {
      case ChannelHistoryOrder.descending:
        return descending;
      case ChannelHistoryOrder.ascending:
        return ascending;
      default:
        throw Exception('Unreachable state');
    }
  }
}

/// Represents history of messages in a channel that can be counted, fetched or removed.
class ChannelHistory {
  final PubNub _core;
  final Channel _channel;
  final Keyset _keyset;

  /// Lower bound on the messages timetoken.
  ///
  /// It is inclusive, meaning if a message has the same timetoken as [from] field,
  /// it will be matched.
  Timetoken? from;

  /// Upper bound on the messages timetoken.
  ///
  /// It is exclusive, meaning if a message has the same timetoken as [to] field
  /// it will NOT be matched.
  Timetoken? to;

  /// Readonly list of fetched messages. It will be empty before first [fetch].
  List<BaseMessage> get messages => _messages;
  List<BaseMessage> _messages = [];

  /// @nodoc
  ChannelHistory(this._core, this._channel, this._keyset, this.from, this.to);

  /// Returns a number of messages after [from].
  ///
  /// If [from] is `null`, it's treated as `Timetoken(1)`.
  /// [to] parameter is disregarded.
  Future<int> count() async {
    var result = await defaultFlow(
        keyset: _keyset,
        core: _core,
        params: CountMessagesParams(_keyset,
            channels: {_channel.name},
            timetoken: from ?? Timetoken(BigInt.one)),
        serialize: (object, [_]) => CountMessagesResult.fromJson(object));

    return result.channels[_channel.name]!;
  }

  /// Delete all matching messages based on [Channel.history] description.
  ///
  /// * if [to] is `null` and [from] in `null`, then it will work on all messages.
  /// * if [to] is `null` and [from] is defined, then it will work on all messages since [from].
  /// * if [to] is defined and [from] is `null`, then it will work on all messages up to [to].
  /// * if both [to] and [from] are defined, then it will work on messages that were sent between [from] and [to].
  Future<void> delete() async {
    await defaultFlow(
      keyset: _keyset,
      core: _core,
      params:
          DeleteMessagesParams(_keyset, _channel.name, end: from, start: to),
      serialize: (object, [_]) => DeleteMessagesResult.fromJson(object),
    );
  }

  /// Retrieve all matching messages based on [Channel.history] description.
  ///
  /// * if [to] is `null` and [from] in `null`, then it will work on all messages.
  /// * if [to] is `null` and [from] is defined, then it will work on all messages since [from].
  /// * if [to] is defined and [from] is `null`, then it will work on all messages up to [to].
  /// * if both [to] and [from] are defined, then it will work on messages that were sent between [from] and [to].
  Future<void> fetch() async {
    var _cursor = from;
    _messages = [];

    do {
      var result = await defaultFlow(
          keyset: _keyset,
          core: _core,
          params: FetchHistoryParams(_keyset, _channel.name,
              reverse: true,
              count: 100,
              start: _cursor,
              end: to,
              includeToken: true),
          serialize: (object, [_]) => FetchHistoryResult.fromJson(object));

      _cursor = result.endTimetoken;
      _messages.addAll(await Future.wait(result.messages.map((message) async {
        if (_keyset.cipherKey != null) {
          message['message'] = await _core.parser.decode(_core.crypto
              .decrypt(_keyset.cipherKey!, message['message'] as String));
        }
        print(message);
        return BaseMessage(
          publishedAt: Timetoken(BigInt.from(message['timetoken'])),
          content: message['message'],
          originalMessage: message,
        );
      })));
    } while (_cursor.value != BigInt.from(0));
  }
}

/// Represents readonly history of messages in a channel.
///
/// It fetches messages in chunks only when requested using [more] call.
class PaginatedChannelHistory {
  final PubNub _core;
  final Channel _channel;
  final Keyset _keyset;

  /// Readonly list of messages. It will be empty before first [more] call.
  List<BaseMessage> get messages => _messages;
  final List<BaseMessage> _messages = [];

  /// Lower bound of fetched messages timetokens. Readonly.
  Timetoken? get startTimetoken => _startTimetoken;
  Timetoken? _startTimetoken;

  /// Upper bound of fetched messages timetokens. Readonly.
  Timetoken? get endTimetoken => _endTimetoken;
  Timetoken? _endTimetoken;

  /// Order in which messages are fetched.
  ChannelHistoryOrder get order => _order;
  final ChannelHistoryOrder _order;

  /// Maximum number of fetched messages when calling [more].
  int get chunkSize => _chunkSize;
  final int _chunkSize;

  /// @nodoc
  PaginatedChannelHistory(
      this._core, this._channel, this._keyset, this._order, this._chunkSize);

  bool _hasMoreOverride = false;
  Timetoken? _cursor;

  /// Returns true if there are more messages to be fetched.
  ///
  /// Keep in mind, that before the first [more] call,
  /// it will always be true.
  bool get hasMore =>
      _hasMoreOverride == false && _cursor?.value != BigInt.zero;

  /// Resets the history to the beginning.
  void reset() {
    _cursor = null;
    _messages.clear();
  }

  /// Fetches more messages and stores them in [messages].
  Future<FetchHistoryResult> more() async {
    var result = await defaultFlow(
        keyset: _keyset,
        core: _core,
        params: FetchHistoryParams(_keyset, _channel.name,
            reverse: _order.choose(ascending: true, descending: false),
            count: _chunkSize,
            start: _cursor,
            includeToken: true),
        serialize: (object, [_]) => FetchHistoryResult.fromJson(object));

    if (result.messages.length < _chunkSize) {
      _hasMoreOverride = true;
    }

    if (_startTimetoken == null && _endTimetoken == null) {
      _startTimetoken = result.startTimetoken;
      _endTimetoken = result.endTimetoken;
    }

    if (_order == ChannelHistoryOrder.descending) {
      _cursor = result.startTimetoken;

      if (result.startTimetoken.value != BigInt.zero) {
        _startTimetoken = result.startTimetoken;
      }
    } else {
      _cursor = result.endTimetoken;

      if (result.endTimetoken.value != BigInt.zero) {
        _endTimetoken = result.endTimetoken;
      }
    }

    _messages.addAll(await Future.wait(result.messages.map((message) async {
      if (_keyset.cipherKey != null) {
        message['message'] = await _core.parser.decode(_core.crypto
            .decrypt(_keyset.cipherKey!, message['message'] as String));
      }
      return BaseMessage(
        originalMessage: message,
        publishedAt: Timetoken(BigInt.from(message['timetoken'])),
        content: message['message'],
      );
    })));

    return result;
  }
}
