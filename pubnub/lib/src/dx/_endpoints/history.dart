import 'dart:convert';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

typedef decryptWithKey = List<int> Function(CipherKey key, List<int> data);
typedef decrypt = List<int> Function(List<int> data);

class FetchHistoryParams extends Parameters {
  Keyset keyset;
  String channel;

  int? count;
  bool? reverse;
  Timetoken? start;
  Timetoken? end;
  bool? includeToken;
  bool? includeMeta;

  FetchHistoryParams(this.keyset, this.channel,
      {this.count,
      this.reverse,
      this.start,
      this.end,
      this.includeMeta,
      this.includeToken})
      : assert(channel.isNotEmpty);

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
      'uuid': '${keyset.uuid}'
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of paginated history endpoint call.
///
/// {@category Results}
class FetchHistoryResult extends Result {
  final List<dynamic> messages;

  final Timetoken startTimetoken;
  final Timetoken endTimetoken;

  FetchHistoryResult._(this.messages, this.startTimetoken, this.endTimetoken);

  factory FetchHistoryResult.fromJson(dynamic object) {
    if (object is List) {
      return FetchHistoryResult._(
          object[0],
          Timetoken(BigInt.parse('${object[1]}')),
          Timetoken(BigInt.parse('${object[2]}')));
    }

    throw getExceptionFromAny(object);
  }
}

class BatchHistoryParams extends Parameters {
  Keyset keyset;
  Set<String> channels;

  int? max;
  bool? reverse;
  Timetoken? start;
  Timetoken? end;
  bool? includeMeta;
  bool? includeMessageActions;
  bool? includeUUID;
  bool? includeMessageType;
  bool? includeCustomMessageType;

  BatchHistoryParams(this.keyset, this.channels,
      {this.max,
      this.reverse,
      this.start,
      this.end,
      this.includeMeta,
      this.includeMessageActions,
      this.includeMessageType,
      this.includeCustomMessageType,
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
      if (includeCustomMessageType != null)
        'include_custom_message_type': '$includeCustomMessageType',
      if (includeUUID != null) 'include_uuid': '$includeUUID',
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      'uuid': '${keyset.uuid}'
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

  /// If `includeUUID` was true, this will contain UUID of the sender.
  /// Otherwise, it will be `null`.
  String? uuid;

  /// Type of the message.
  MessageType messageType;

  /// If `includeMessageActions` was true, this will contain message actions.
  /// Otherwise, it will be `null`.
  Map<String, dynamic>? actions;

  /// If `includeMeta` was true, this will contain message meta.
  /// Otherwise, it will be `null`.
  Map<String, dynamic>? meta;

  /// This field will contain PubNubException if message decryption is failed
  /// for given `message`.
  PubNubException? error;

  /// If message has customMessageType, this will contain it.
  /// Otherwise, it will be `null`.
  String? customMessageType;

  BatchHistoryResultEntry._(
      this.message,
      this.timetoken,
      this.uuid,
      this.messageType,
      this.actions,
      this.meta,
      this.error,
      this.customMessageType);

  /// @nodoc
  factory BatchHistoryResultEntry.fromJson(Map<String, dynamic> object,
      {CipherKey? cipherKey, Function? decryptFunction}) {
    var message;
    PubNubException? error;
    if (cipherKey == null && decryptFunction is decryptWithKey) {
      message = object['message'];
    } else {
      try {
        if (!(object['message'] is String)) {
          throw FormatException('not a base64 string.');
        }
        message = decryptFunction is decryptWithKey
            ? json.decode(utf8.decode(decryptFunction(cipherKey!,
                base64.decode(object['message'] as String).toList())))
            : json.decode(utf8.decode(decryptFunction!(
                base64.decode(object['message'] as String).toList())));
      } on CryptoException catch (e) {
        message = object['message'];
        error = e;
      } on FormatException catch (e) {
        message = object['message'];
        error = PubNubException(
            'Can not decrypt the message payload. Please check keyset or crypto configuration. ${e.message}');
      }
    }

    return BatchHistoryResultEntry._(
        message,
        Timetoken(BigInt.parse('${object['timetoken']}')),
        object['uuid'],
        MessageTypeExtension.fromInt(object['message_type']),
        object['actions'],
        object['meta'] == '' ? null : object['meta'],
        error,
        object['custom_message_type']);
  }
}

/// Result of batch history endpoint call.
///
/// {@category Results}
class BatchHistoryResult extends Result {
  /// Map of channels to a list of messages represented by [BatchHistoryResultEntry].
  Map<String, List<BatchHistoryResultEntry>> channels;

  /// @nodoc
  MoreHistory? more;

  BatchHistoryResult._(this.channels, this.more);

  /// @nodoc
  factory BatchHistoryResult.fromJson(Map<String, dynamic> object,
      {CipherKey? cipherKey, Function? decryptFunction}) {
    var result = DefaultResult.fromJson(object);

    return BatchHistoryResult._(
        (result.otherKeys['channels'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map((entry) => BatchHistoryResultEntry.fromJson(entry,
                        cipherKey: cipherKey, decryptFunction: decryptFunction))
                    .toList())),
        result.otherKeys['more'] != null
            ? MoreHistory.fromJson(result.otherKeys['more'])
            : null);
  }
}

class MoreHistory {
  String url;
  String start;
  int count;

  MoreHistory._(this.url, this.start, this.count);

  factory MoreHistory.fromJson(dynamic object) {
    return MoreHistory._(object['url'] as String, object['start'] as String,
        object['max'] as int);
  }
}

class CountMessagesParams extends Parameters {
  Keyset keyset;
  Map<String, Timetoken>? channelsTimetoken;

  Timetoken? timetoken;
  Set<String>? channels;

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
        channelsTimetoken!.keys.join(',')
      else
        channels!.join(',')
    ];

    var queryParameters = {
      if (channelsTimetoken != null)
        'channelsTimetoken': channelsTimetoken?.values.join(',')
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

  CountMessagesResult._(this.channels);

  /// @nodoc
  factory CountMessagesResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return CountMessagesResult._(
        (result.otherKeys['channels'] as Map<String, dynamic>)
            .cast<String, int>());
  }
}

class DeleteMessagesParams extends Parameters {
  Keyset keyset;
  String channel;

  Timetoken? start;
  Timetoken? end;

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
