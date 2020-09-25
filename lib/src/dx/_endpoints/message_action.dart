import 'package:pubnub/core.dart';

class FetchMessageActionsParams extends Parameters {
  Keyset keyset;
  String channel;

  Timetoken start;
  Timetoken end;
  int limit;

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
  List<MessageAction> _actions;
  dynamic _moreActions;

  dynamic get moreActions => _moreActions;

  /// List of message actions.
  List<MessageAction> get actions => _actions ?? [];
  set actions(List<MessageAction> actions) => _actions = actions;

  /// @nodoc
  FetchMessageActionsResult();

  /// @nodoc
  factory FetchMessageActionsResult.fromJson(dynamic object) {
    return FetchMessageActionsResult()
      .._actions = (object['data'] as List)
          ?.map((e) => e == null ? null : MessageAction.fromJson(e))
          ?.toList()
      .._moreActions =
          object['more'] != null ? MoreAction.fromJson(object['more']) : null;
  }
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

  MessageAction._();

  /// @nodoc
  factory MessageAction.fromJson(dynamic object) {
    return MessageAction._()
      ..type = object['type'] as String
      ..value = object['value'] as String
      ..actionTimetoken = "${object['actionTimetoken']}"
      ..messageTimetoken = "${object['messageTimetoken']}"
      ..uuid = object['uuid'] as String;
  }
}

/// @nodoc
class MoreAction {
  String url;
  String start;
  String end;
  int limit;

  MoreAction();

  factory MoreAction.fromJson(dynamic object) {
    return MoreAction()
      ..url = object['url'] as String
      ..start = object['start'] as String
      ..end = object['end'] as String
      ..limit = object['limit'] as int;
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
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}'
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
  int _status;
  MessageAction _data;
  Map<String, dynamic> _error;

  int get status => _status;
  MessageAction get data => _data;
  Map<String, dynamic> get error => _error;

  AddMessageActionResult();

  factory AddMessageActionResult.fromJson(dynamic object) {
    return AddMessageActionResult()
      .._status = object['status']
      .._data =
          object['data'] != null ? MessageAction.fromJson(object['data']) : null
      .._error = object['error'];
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
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}'
    };

    return Request.delete(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of delete message actions endpoint call.
///
/// {@category Results}
class DeleteMessageActionResult extends Result {
  int _status;
  dynamic _data;
  Map<String, dynamic> _error;

  int get status => _status;
  dynamic get data => _data;
  Map<String, dynamic> get error => _error;

  DeleteMessageActionResult();

  factory DeleteMessageActionResult.fromJson(dynamic object) {
    return DeleteMessageActionResult()
      .._status = object['status'] as int
      .._data = object['data']
      .._error = object['error'];
  }
}
