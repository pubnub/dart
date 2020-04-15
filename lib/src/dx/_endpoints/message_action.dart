import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class FetchMessageActionsParams extends Parameters {
  Keyset keyset;
  String channel;

  Timetoken start;
  Timetoken end;
  int limit;

  FetchMessageActionsParams(this.keyset, this.channel,
      {this.start, this.end, this.limit});

  Request toRequest() {
    List<String> pathSegments = [
      'v1',
      'message-actions',
      keyset.subscribeKey,
      'channel',
      channel,
    ];

    Map<String, String> queryParameters = {
      if (start != null) 'start': '$start',
      if (end != null) 'end': '$end',
      if (limit != null) 'limit': limit.toString(),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
    };

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class FetchMessageActionsResult extends Result {
  int _status;
  List<MessageAction> _actions;
  dynamic _moreActions;
  Map<String, dynamic> _error;

  dynamic get moreActions => _moreActions;
  Map<String, dynamic> get error => _error;

  int get status => _status;
  set status(int status) => _status = status;

  List<MessageAction> get actions => _actions ?? [];
  set actions(List<MessageAction> actions) => _actions = actions;

  FetchMessageActionsResult();

  factory FetchMessageActionsResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return FetchMessageActionsResult()
      .._status = result.status as int
      .._actions = (result.data as List)
          ?.map((e) => e == null ? null : MessageAction.fromJson(e))
          ?.toList()
      .._moreActions = result.otherKeys['more'] != null
          ? MoreAction.fromJson(result.otherKeys['more'])
          : null
      .._error = object['error'];
  }
}

class MessageAction {
  String type;
  String value;
  String actionTimetoken;
  String messageTimetoken;
  String uuid;

  MessageAction();

  factory MessageAction.fromJson(dynamic object) {
    return MessageAction()
      ..type = object['type'] as String
      ..value = object['value'] as String
      ..actionTimetoken = "${object['actionTimetoken']}"
      ..messageTimetoken = "${object['messageTimetoken']}"
      ..uuid = object['uuid'] as String;
  }
}

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

  Request toRequest() {
    List<String> pathSegments = [
      'v1',
      'message-actions',
      keyset.subscribeKey,
      'channel',
      channel,
      'message',
      '$messageTimetoken'
    ];

    Map<String, String> queryParameters = {
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}'
    };

    return Request(
        type: RequestType.post,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        body: messageAction);
  }
}

class AddMessageActionResult extends Result {
  int _status;
  MessageAction _data;
  Map<String, dynamic> _error;

  int get status => _status;
  MessageAction get data => _data;
  Map<String, dynamic> get error => _error;

  AddMessageActionResult();

  factory AddMessageActionResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return AddMessageActionResult()
      .._status = result.status
      .._data = result.data != null ? MessageAction.fromJson(result.data) : null
      .._error = result.error;
  }
}

class DeleteMessageActionParams extends Parameters {
  Keyset keyset;
  String channel;

  Timetoken messageTimetoken;
  Timetoken actionTimetoken;

  DeleteMessageActionParams(
      this.keyset, this.channel, this.messageTimetoken, this.actionTimetoken);

  Request toRequest() {
    List<String> pathSegments = [
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

    return Request(
        type: RequestType.delete,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class DeleteMessageActionResult extends Result {
  int _status;
  dynamic _data;
  Map<String, dynamic> _error;

  int get status => _status;
  dynamic get data => _data;
  Map<String, dynamic> get error => _error;

  DeleteMessageActionResult();

  factory DeleteMessageActionResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return DeleteMessageActionResult()
      .._status = result.status as int
      .._data = result.data
      .._error = result.error;
  }
}
