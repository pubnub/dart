import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/message_action.dart';

export '../_endpoints/message_action.dart'
    show
        MessageAction,
        FetchMessageActionsResult,
        AddMessageActionResult,
        DeleteMessageActionResult,
        MoreAction;

mixin MessageActionDx on Core {
  /// Returns all message actions of a given [channel].
  ///
  /// Pagination can be controlled using [from], [to] and [limit] parameters.
  ///
  /// If [from] is not provided, the server uses the current time.
  ///
  /// If both [to] or [limit] are null, it will fetch the maximum amount of message actions -
  /// the server will try and retrieve all actions for the channel, going back in time forever.
  /// default and maximum value for [limit] is 100.
  ///
  /// In some cases, due to internal limitations on the number of queries performed per request,
  /// the server will not be able to give the full range of actions requested.
  Future<FetchMessageActionsResult> fetchMessageActions(String channel,
      {Timetoken? from,
      Timetoken? to,
      int? limit = 100,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    Ensure(channel).isNotEmpty('channel');

    return defaultFlow(
        keyset: keyset,
        core: this,
        params: FetchMessageActionsParams(keyset, channel,
            start: from, end: to, limit: limit),
        serialize: (object, [_]) => FetchMessageActionsResult.fromJson(object));
  }

  /// This method adds a message action to a parent message.
  ///
  /// [type] and [value] cannot be empty.
  ///
  /// Parent message is a normal message identified by a combination of subscription key, [channel] and [timetoken].
  /// > **Important!**
  /// >
  /// > Server *does not* validate if the parent message exists at the time of adding the message action.
  /// >
  /// > It does, however, check if you have not **already added this particular action** to the parent message.
  ///
  /// In other words, for a given parent message, there can be only one message action with [type] and [value].
  Future<AddMessageActionResult> addMessageAction(
      {required String type,
      required String value,
      required String channel,
      required Timetoken timetoken,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    Ensure(type).isNotEmpty('message action type');
    Ensure(value).isNotEmpty('message action value');
    Ensure(timetoken).isNotNull('message timetoken');

    var addMessageActionBody =
        await super.parser.encode({'type': type, 'value': value});

    var params = AddMessageActionParams(
        keyset, channel, timetoken, addMessageActionBody);

    return defaultFlow<AddMessageActionParams, AddMessageActionResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => AddMessageActionResult.fromJson(object));
  }

  /// This method removes an existing message action (identified by [actionTimetoken])
  /// from a parent message (identified by [messageTimetoken]) on a [channel].
  ///
  /// It is technically possible to delete more than one action with this method;
  /// if the same UUID posted different actions on the same parent message at the same time.
  ///
  /// If all goes well, the action(s) will be deleted from the database,
  /// and one or more "action remove event" messages will be published in realtime
  /// on the same channel as the parent message.
  Future<DeleteMessageActionResult> deleteMessageAction(String channel,
      {required Timetoken messageTimetoken,
      required Timetoken actionTimetoken,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    Ensure(channel).isNotEmpty('channel');

    var params = DeleteMessageActionParams(
        keyset, channel, messageTimetoken, actionTimetoken);

    return defaultFlow<DeleteMessageActionParams, DeleteMessageActionResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => DeleteMessageActionResult.fromJson(object));
  }
}
