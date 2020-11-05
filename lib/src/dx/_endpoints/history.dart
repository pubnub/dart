import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

typedef decryptFunction = List<int> Function(CipherKey key, String data);

class FetchHistoryParams extends Parameters {
  Keyset keyset;
  String channel;

  int count;
  bool reverse;
  Timetoken start;
  Timetoken end;
  bool includeToken;
  bool includeMeta;

  FetchHistoryParams(this.keyset, this.channel,
      {this.count,
      this.reverse,
      this.start,
      this.end,
      this.includeMeta,
      this.includeToken});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'history',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      channel,
    ];

    var queryParameters = {
      if (count != null) 'count': '$count',
      if (reverse != null) 'reverse': '$reverse',
      if (start != null) 'start': '$start',
      if (end != null) 'end': '$end',
      if (includeToken != null) 'include_token': '$includeToken',
      if (includeMeta != null) 'include_meta': '$includeMeta',
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}'
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of paginated history endpoint call.
///
/// {@category Results}
class FetchHistoryResult extends Result {
  List<dynamic> messages;

  Timetoken startTimetoken;
  Timetoken endTimetoken;

  FetchHistoryResult();

  factory FetchHistoryResult.fromJson(dynamic object) {
    if (object is List) {
      return FetchHistoryResult()
        ..messages = object[0]
        ..startTimetoken = Timetoken(object[1])
        ..endTimetoken = Timetoken(object[2]);
    }

    throw getExceptionFromAny(object);
  }
}

class BatchHistoryParams extends Parameters {
  Keyset keyset;
  Set<String> channels;

  int max;
  bool reverse;
  Timetoken start;
  Timetoken end;
  bool includeMeta;
  bool includeMessageActions;
  bool includeUUID;
  bool includeMessageType;

  BatchHistoryParams(this.keyset, this.channels,
      {this.max,
      this.reverse,
      this.start,
      this.end,
      this.includeMeta,
      this.includeMessageActions,
      this.includeMessageType,
      this.includeUUID})
      : assert(channels.isNotEmpty);

  @override
  Request toRequest() {
    var pathSegments = [
      'v3',
      includeMessageActions == true ? 'history-with-actions' : 'history',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      channels.join(',')
    ];

    var queryParameters = {
      if (max != null) 'max': '$max',
      if (reverse != null) 'reverse': '$reverse',
      if (start != null) 'start': '$start',
      if (end != null) 'end': '$end',
      if (includeMeta != null) 'include_meta': '$includeMeta',
      if (includeMessageType != null)
        'include_message_type': '$includeMessageType',
      if (includeUUID != null) 'include_uuid': '$includeUUID',
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}'
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Message from batch history endpoint.
///
/// {@category Results}
class BatchHistoryResultEntry {
  /// Contents of the message.
  dynamic message;

  /// Original timetoken of the message.
  Timetoken timetoken;

  /// UUID of the sender.
  String uuid;

  /// Type of the message.
  MessageType messageType;

  /// If `includeMessageActions` was true, this will contain message actions.
  /// Otherwise, it will be `null`.
  Map<String, dynamic> actions;

  /// If `includeMeta` was true, this will contain message meta.
  /// Otherwise, it will be `null`.
  Map<String, dynamic> meta;

  BatchHistoryResultEntry._();

  /// @nodoc
  factory BatchHistoryResultEntry.fromJson(Map<String, dynamic> object,
      {CipherKey cipherKey, Function decryptFunction}) {
    return BatchHistoryResultEntry._()
      ..timetoken = Timetoken(int.tryParse(object['timetoken']))
      ..uuid = object['uuid']
      ..messageType = (object['message_type'] is int)
          ? MessageTypeExtension.fromInt(object['message_type'])
          : null
      ..message = cipherKey == null
          ? object['message']
          : decryptFunction(cipherKey, object['message'])
      ..actions = object['actions']
      ..meta = object['meta'];
  }
}

/// Result of batch history endpoint call.
///
/// {@category Results}
class BatchHistoryResult extends Result {
  /// Map of channels to a list of messages represented by [BatchHistoryResultEntry].
  Map<String, List<BatchHistoryResultEntry>> channels;

  /// @nodoc
  MoreHistory more;

  BatchHistoryResult();

  /// @nodoc
  factory BatchHistoryResult.fromJson(Map<String, dynamic> object,
      {CipherKey cipherKey, Function decryptFunction}) {
    var result = DefaultResult.fromJson(object);

    return BatchHistoryResult()
      ..channels = (result.otherKeys['channels'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map((entry) => BatchHistoryResultEntry.fromJson(entry,
                      cipherKey: cipherKey, decryptFunction: decryptFunction))
                  .toList()))
      ..more = result.otherKeys['more'] != null
          ? MoreHistory.fromJson(result.otherKeys['more'])
          : null;
  }
}

class MoreHistory {
  String url;
  String start;
  int count;

  MoreHistory();

  factory MoreHistory.fromJson(dynamic object) {
    return MoreHistory()
      ..url = object['url'] as String
      ..start = object['start'] as String
      ..count = object['limit'] as int;
  }
}

class CountMessagesParams extends Parameters {
  Keyset keyset;
  Map<String, Timetoken> channelsTimetoken;

  Timetoken timetoken;
  Set<String> channels;

  CountMessagesParams(this.keyset,
      {this.channelsTimetoken, this.timetoken, this.channels});

  @override
  Request toRequest() {
    var pathSegments = [
      'v3',
      'history',
      'sub-key',
      keyset.subscribeKey,
      'message-counts',
      if (channelsTimetoken != null)
        channelsTimetoken.keys.join(',')
      else
        channels.join(',')
    ];

    var queryParameters = {
      if (channelsTimetoken != null)
        'channelsTimetoken': channelsTimetoken.values.join(',')
      else
        'timetoken': '$timetoken',
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of count messages endpoint call.
///
/// {@category Results}
class CountMessagesResult extends Result {
  /// Map of channels to message counts.
  Map<String, int> channels;

  CountMessagesResult._();

  /// @nodoc
  factory CountMessagesResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return CountMessagesResult._()
      ..channels = (result.otherKeys['channels'] as Map<String, dynamic>)
          .cast<String, int>();
  }
}

class DeleteMessagesParams extends Parameters {
  Keyset keyset;
  String channel;

  Timetoken start;
  Timetoken end;

  DeleteMessagesParams(this.keyset, this.channel, {this.start, this.end});

  @override
  Request toRequest() {
    var pathSegments = [
      'v3',
      'history',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      channel
    ];

    var queryParameters = {
      if (start != null) 'start': '$start',
      if (end != null) 'end': '$end',
    };

    return Request.delete(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class DeleteMessagesResult extends Result {
  DeleteMessagesResult._();

  factory DeleteMessagesResult.fromJson(dynamic object) =>
      DeleteMessagesResult._();
}
