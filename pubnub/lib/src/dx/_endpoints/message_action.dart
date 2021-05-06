import 'package:pubnub/core.dart';

class FetchMessageActionsParams extends Parameters {
  Keyset keyset;
  String channel;

  Timetoken? start;
  Timetoken? end;
  int? limit;

  FetchMessageActionsParams(this.keyset, this.channel,
      {this.start, this.end, this.limit});

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'message-actions',
      keyset.subscribeKey,
      'channel',
      channel,
    ];

    var queryParameters = {
      if (start != null) 'start': '$start',
      if (end != null) 'end': '$end',
      if (limit != null) 'limit': limit.toString(),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of fetch message actions endpoint call.
///
/// {@category Results}
class FetchMessageActionsResult extends Result {
  List<MessageAction> actions;
  MoreAction? moreActions;

  /// @nodoc
  FetchMessageActionsResult(this.actions, {this.moreActions});

  /// @nodoc
  factory FetchMessageActionsResult.fromJson(dynamic object) =>
      FetchMessageActionsResult(
          (object['data'] as List)
              .map((e) => MessageAction.fromJson(e))
              .toList(),
          moreActions: object['more'] != null
              ? MoreAction.fromJson(object['more'])
              : null);
}

/// Represents a message action.
///
/// {@category Results}
class MessageAction {
  /// Type of this message action.
  String type;

  /// Value of this message action.
  String value;

  /// Timetoken of when this message action has been added.
  String actionTimetoken;

  /// Timetoken of the parent message.
  String messageTimetoken;

  /// UUID of who added this message action.
  String uuid;

  MessageAction._(this.type, this.value, this.actionTimetoken,
      this.messageTimetoken, this.uuid);

  /// @nodoc
  factory MessageAction.fromJson(dynamic object) {
    return MessageAction._(
        object['type'] as String,
        object['value'] as String,
        "${object['actionTimetoken']}",
        "${object['messageTimetoken']}",
        object['uuid'] as String);
  }
}

/// @nodoc
class MoreAction {
  String url;
  String start;
  String end;
  int limit;

  MoreAction._(this.url, this.start, this.end, this.limit);

  factory MoreAction.fromJson(dynamic object) {
    return MoreAction._(object['url'] as String, object['start'] as String,
        object['end'] as String, object['limit'] as int);
  }
}

class AddMessageActionParams extends Parameters {
  Keyset keyset;
  String channel;
  Timetoken messageTimetoken;

  String messageAction;

  AddMessageActionParams(
      this.keyset, this.channel, this.messageTimetoken, this.messageAction);

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'message-actions',
      keyset.subscribeKey,
      'channel',
      channel,
      'message',
      '$messageTimetoken'
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      'uuid': '${keyset.uuid}'
    };

    return Request.post(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        body: messageAction);
  }
}

/// Result of add message actions endpoint call.
///
/// {@category Results}
class AddMessageActionResult extends Result {
  final MessageAction _action;

  MessageAction get action => _action;

  AddMessageActionResult._(this._action);

  factory AddMessageActionResult.fromJson(dynamic object) {
    return AddMessageActionResult._(MessageAction.fromJson(object['data']));
  }
}

class DeleteMessageActionParams extends Parameters {
  Keyset keyset;
  String channel;

  Timetoken messageTimetoken;
  Timetoken actionTimetoken;

  DeleteMessageActionParams(
      this.keyset, this.channel, this.messageTimetoken, this.actionTimetoken);

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'message-actions',
      keyset.subscribeKey,
      'channel',
      channel,
      'message',
      '$messageTimetoken',
      'action',
      '$actionTimetoken'
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      'uuid': '${keyset.uuid}'
    };

    return Request.delete(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of delete message actions endpoint call.
///
/// {@category Results}
class DeleteMessageActionResult extends Result {
  DeleteMessageActionResult._();

  factory DeleteMessageActionResult.fromJson(dynamic object) {
    return DeleteMessageActionResult._();
  }
}
