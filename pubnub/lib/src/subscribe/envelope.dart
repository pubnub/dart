import 'package:pubnub/core.dart';

/// Represents a message received from a subscription.
///
/// {@category Results}
/// {@category Basic Features}
class Envelope extends BaseMessage {
  String shard;
  String subscriptionPattern;
  String channel;
  MessageType messageType;
  int flags;
  UUID uuid;

  Timetoken originalTimetoken;
  int originalRegion;
  @override
  Timetoken publishedAt;
  int region;

  @override
  dynamic content;
  dynamic userMeta;
  @override
  dynamic originalMessage;

  dynamic get payload => content;

  /// @nodoc
  Envelope.fromJson(dynamic object) {
    shard = object['a'] as String;
    subscriptionPattern = object['b'] as String;
    channel = object['c'] as String;
    content = object['d'];
    messageType = MessageTypeExtension.fromInt(object['e'] as int);
    flags = object['f'] as int;
    uuid = object['i'] != null ? UUID(object['i'] as String) : null;
    originalTimetoken =
        object['o'] != null ? Timetoken(int.tryParse(object['o']['t'])) : null;
    originalRegion = object['o'] != null ? object['o']['r'] : null;
    publishedAt =
        object['p'] != null ? Timetoken(int.tryParse(object['p']['t'])) : null;
    region = object['p'] != null ? object['p']['r'] : null;
    userMeta = object['u'];
    originalMessage = object;
  }
}

/// Represents a presence action.
enum PresenceAction { join, leave, timeout, stateChange, interval }

/// @nodoc
PresenceAction fromString(String action) => const {
      'join': PresenceAction.join,
      'leave': PresenceAction.leave,
      'timeout': PresenceAction.timeout,
      'state-change': PresenceAction.stateChange,
      'interval': PresenceAction.interval,
    }[action];

/// Represents an event in presence.
///
/// {@category Results}
class PresenceEvent {
  Envelope envelope;

  PresenceAction action;
  UUID uuid;
  int occupancy;
  Timetoken get timetoken => envelope.publishedAt;

  List<UUID> get join => (envelope.payload['join'] as List<dynamic> ?? [])
      .cast<String>()
      .map((uuid) => UUID(uuid))
      .toList();
  List<UUID> get leave => (envelope.payload['leave'] as List<dynamic> ?? [])
      .cast<String>()
      .map((uuid) => UUID(uuid))
      .toList();

  PresenceEvent.fromEnvelope(this.envelope)
      : action = fromString(envelope.payload['action'] as String),
        uuid = UUID(envelope.payload['uuid'] as String),
        occupancy = envelope.payload['occupancy'] as int;
}
