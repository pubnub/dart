import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

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

  Request toRequest() {
    List<String> pathSegments = [
      'v2',
      'history',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      channel,
    ];

    Map<String, String> queryParameters = {
      if (count != null) 'count': '$count',
      if (reverse != null) 'reverse': '$reverse',
      if (start != null) 'start': '$start',
      if (end != null) 'end': '$end',
      if (includeToken != null) 'include_token': '$includeToken',
      if (includeMeta != null) 'include_meta': '$includeMeta',
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}'
    };

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

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

  BatchHistoryParams(this.keyset, this.channels,
      {this.max, this.reverse, this.start, this.end, this.includeMeta})
      : assert(channels.length != 0);

  Request toRequest() {
    List<String> pathSegments = [
      'v3',
      'history',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      channels.join(',')
    ];

    Map<String, String> queryParameters = {
      if (max != null) 'max': '$max',
      if (reverse != null) 'reverse': '$reverse',
      if (start != null) 'start': '$start',
      if (end != null) 'end': '$end',
      if (includeMeta != null) 'include-_meta': '$includeMeta',
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}'
    };

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class BatchHistoryResultEntry {
  dynamic message;
  Timetoken timetoken;

  BatchHistoryResultEntry._();

  factory BatchHistoryResultEntry.fromJson(Map<String, dynamic> object) {
    return BatchHistoryResultEntry._()
      ..timetoken = Timetoken(object['timestamp'] as int)
      ..message = object['message'];
  }
}

class BatchHistoryResult extends Result {
  Map<String, List<BatchHistoryResultEntry>> channels;

  BatchHistoryResult._();

  factory BatchHistoryResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return BatchHistoryResult._()
      ..channels = (result.otherKeys['channels'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
              key,
              (value as List<dynamic>)
                  .map((entry) => BatchHistoryResultEntry.fromJson(entry))
                  .toList()));
  }
}

class CountMessagesParams extends Parameters {
  Keyset keyset;
  Map<String, Timetoken> channelsTimetoken;

  Timetoken timetoken;
  Set<String> channels;

  CountMessagesParams(this.keyset,
      {this.channelsTimetoken, this.timetoken, this.channels});

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

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class CountMessagesResult extends Result {
  Map<String, int> channels;

  CountMessagesResult._();

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

    return Request(
        type: RequestType.delete,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class DeleteMessagesResult extends Result {
  DeleteMessagesResult._();

  factory DeleteMessagesResult.fromJson(dynamic object) =>
      DeleteMessagesResult._();
}
