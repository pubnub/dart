import 'dart:async';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/_endpoints/presence.dart';
import 'package:pubnub/src/dx/_endpoints/publish.dart';
import 'package:pubnub/src/dx/_endpoints/message_action.dart';
import 'package:pubnub/src/dx/subscribe/subscription.dart';

import 'channel_history.dart';

class Channel {
  PubNub _core;
  Keyset _keyset;
  String name;

  Channel(this._core, this._keyset, this.name);

  /// Subscribes to channel [name]. Returns [Subscription] instance.
  ///
  /// If you set [withPresence] to true, it will also subscribe to presence events.
  Subscription subscribe({bool withPresence = false}) {
    return _core.subscribe(
        keyset: _keyset, channels: {name}, withPresence: withPresence);
  }

  /// Publishes [message] to a channel [name].
  ///
  /// You can override the default account configuration on message
  /// saving using [storeMessage] flag - `true` to save and `false` to discard.
  /// Leave this option unset if you want to use the default.
  ///
  /// You can set a per-message time to live in storage using [ttl] option.
  /// If set to `0`, message won't expire.
  /// If unset, expiration will fall back to default.
  Future<PublishResult> publish(dynamic message, {bool storeMessage, int ttl}) {
    return _core.publish(name, message,
        storeMessage: storeMessage, ttl: ttl, keyset: _keyset);
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
  ChannelHistory messages({Timetoken from, Timetoken to}) =>
      ChannelHistory(_core, this, _keyset, from, to);

  /// Explicitly announces a leave event for this keyset/channel combination.
  Future<LeaveResult> leave() {
    return _core.announceLeave(keyset: _keyset, channels: {name});
  }

  /// Returns all message actions of this channel
  ///
  /// Pagination can be controlled using [start], [end] and [limit] parameters,
  /// If [from] is not provided, the server uses the current time.
  ///
  /// Providing no end or limit means there is "no limit" to the number of actions being requested.
  /// In this event the server will try and retrieve all actions for the channel, going back in time forever.
  Future<FetchMessageActionsResult> fetchMessageActions(
          {Timetoken start, Timetoken end, int limit}) =>
      _core.fetchMessageActions(name,
          start: start, end: end, limit: limit, keyset: _keyset);

  /// You can use this method to post actions on a "parent message"
  /// by specifying message action details [type], [value] and [timetoken] of the parent message.
  ///
  /// The server does not validate that the parent message exists at the time the action is posted.
  /// The server does, however, check that you have not already added this particular action to this message.
  /// In other words, for a given parent message (identified by [subkey], [channel], [timetoken]),
  ///  there is at most one unique (type, value) pair per uuid.
  ///
  /// Message action contains two properties : action[type] and action[value] and those should not be empty
  /// Empty [type] and/or [value] throws Ensure exception
  Future<AddMessageActionResult> addMessageAction(
          String type, String value, Timetoken messageTimetoken) =>
      _core.addMessageAction(type, value, name, messageTimetoken,
          keyset: _keyset);

  /// Allows users to remove their previously-posted message actions,
  /// by specifying the parent message, and the single timetoken of the action(s) they wish to delete.
  ///
  /// It is technically possible to delete more than one action here,
  /// if the same UUID posted different actions on the same parent message at the same time.
  ///
  /// If all goes well, the action(s) will be deleted from the database,
  /// and one or more "action remove event" messages will be published in realtime
  /// on the same channel as the parent message.
  Future<DeleteMessageActionResult> deleteMessageAction(
          Timetoken messageTimetoken, Timetoken actionTimetoken) =>
      _core.deleteMessageAction(name, messageTimetoken, actionTimetoken,
          keyset: _keyset);
}
