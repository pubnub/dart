import 'package:pubnub/core.dart';
import 'package:pubnub/src/default.dart';

import '../_endpoints/presence.dart';
import '../_endpoints/publish.dart';
import '../_endpoints/message_action.dart';
import 'channel_history.dart';

export 'channel_history.dart'
    show PaginatedChannelHistory, ChannelHistory, ChannelHistoryOrder;

/// Represents a single channel.
///
/// It shouldn't be instantiated directly, instead call [PubNub.channel].
///
/// {@category Basic Features}
class Channel {
  final PubNub _core;
  final Keyset _keyset;
  String name;

  /// @nodoc
  Channel(this._core, this._keyset, this.name);

  /// Publishes [message] to a channel [name].
  ///
  /// You can override the default account configuration on message
  /// saving using [storeMessage] flag - `true` to save and `false` to discard.
  /// Leave this option unset if you want to use the default.
  ///
  /// [meta] parameter is for providing additional information with message
  /// that can be used for stream filtering
  /// * Inorder to make stream filtering work, Provide valid `Object` as meta.
  /// * Invalid type (e.g String) data won't be passed to server.
  ///
  /// To send message to PubNub BLOCKS EventHandler, set [fire] param value to `true`.
  /// Fire message is not replicated, and so will not be received by any subscribers to the channel.
  /// Fire message is also not stored in history.
  ///
  /// You can set a per-message time to live in storage using [ttl] option.
  /// If set to `0`, message won't expire.
  /// If unset, expiration will fall back to default.
  Future<PublishResult> publish(dynamic message,
      {bool? storeMessage, int? ttl, dynamic meta, bool? fire}) {
    return _core.publish(name, message,
        storeMessage: storeMessage,
        ttl: ttl,
        keyset: _keyset,
        meta: meta,
        fire: fire);
  }

  /// Returns [PaginatedChannelHistory]. Most useful in infinite list type scenario.
  ///
  /// If you set the [order] to [ChannelHistoryOrder.ascending], then the messages
  /// will be loaded from oldest to newest. Otherwise, the default behavior is to load
  /// from the newest message to the oldest.
  ///
  /// Overwriting [chunkSize] will allow you to load in smaller chunks.
  /// The default is the maximum value of 100.
  PaginatedChannelHistory history(
          {ChannelHistoryOrder order = ChannelHistoryOrder.descending,
          int chunkSize = 100}) =>
      PaginatedChannelHistory(_core, this, _keyset, order, chunkSize);

  /// Returns [ChannelHistory]. Used to retrieve many messages at once.
  ///
  /// Behaviour of [ChannelHistory] changes based on which of [to] and [from] are available.
  /// * if [to] is `null` and [from] in `null`, then it will work on all messages.
  /// * if [to] is `null` and [from] is defined, then it will work on all messages since [from].
  /// * if [to] is defined and [from] is `null`, then it will work on all messages up to [to].
  /// * if both [to] and [from] are defined, then it will work on messages that were sent between [from] and [to].
  ChannelHistory messages({Timetoken? from, Timetoken? to}) =>
      ChannelHistory(_core, this, _keyset, from, to);

  /// Explicitly announces a leave event for this keyset/channel combination.
  Future<LeaveResult> leave() {
    return _core.announceLeave(keyset: _keyset, channels: {name});
  }

  /// Returns all message actions of this channel.
  ///
  /// Pagination can be controlled using [from], [to] and [limit] parameters.
  ///
  /// If [from] is not provided, the server uses the current time.
  ///
  /// If both [to] or [limit] are null, it will fetch the maximum amount of message actions -
  /// the server will try and retrieve all actions for the channel, going back in time forever.
  Future<FetchMessageActionsResult> fetchMessageActions(
          {Timetoken? from, Timetoken? to, int? limit}) =>
      _core.fetchMessageActions(name,
          from: from, to: to, limit: limit, keyset: _keyset);

  /// This method adds a message action to a parent message.
  ///
  /// [type] and [value] cannot be empty.
  ///
  /// Parent message is a normal message identified by a combination of subscription key, channel [name] and [timetoken].
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
          required Timetoken timetoken}) =>
      _core.addMessageAction(
          type: type,
          value: value,
          channel: name,
          timetoken: timetoken,
          keyset: _keyset);

  /// This method removes an existing message action (identified by [actionTimetoken]) from a parent message (identified by [messageTimetoken]).
  ///
  /// It is technically possible to delete more than one action with this method;
  /// if the same UUID posted different actions on the same parent message at the same time.
  ///
  /// If all goes well, the action(s) will be deleted from the database,
  /// and one or more "action remove event" messages will be published in realtime
  /// on the same channel as the parent message.
  Future<DeleteMessageActionResult> deleteMessageAction(
          {required Timetoken messageTimetoken,
          required Timetoken actionTimetoken}) =>
      _core.deleteMessageAction(name,
          messageTimetoken: messageTimetoken,
          actionTimetoken: actionTimetoken,
          keyset: _keyset);
}
