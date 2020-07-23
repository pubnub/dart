import 'package:pubnub/src/core/core.dart';

enum MessageType { normal, signal, objects, messageAction, file }

MessageType fromInt(int messageType) => const {
      null: MessageType.normal,
      1: MessageType.signal,
      2: MessageType.objects,
      3: MessageType.messageAction,
      4: MessageType.file
    }[messageType];

extension MessageTypeExtension on MessageType {
  int toInt() => const {
        MessageType.normal: null,
        MessageType.signal: 1,
        MessageType.objects: 2,
        MessageType.messageAction: 3,
        MessageType.file: 4,
      }[this];
}

class Envelope {
  String shard;
  String subscriptionPattern;
  String channel;
  MessageType messageType;
  int flags;
  UUID uuid;

  Timetoken originalTimetoken;
  int originalRegion;
  Timetoken timetoken;
  int region;

  dynamic payload;
  dynamic userMeta;
  dynamic originalMessage;

  Envelope.fromJson(dynamic object) {
    shard = object['a'] as String;
    subscriptionPattern = object['b'] as String;
    channel = object['c'] as String;
    payload = object['d'];
    messageType = fromInt(object['e'] as int);
    flags = object['f'] as int;
    uuid = object['i'] != null ? UUID(object['i'] as String) : null;
    originalTimetoken =
        object['o'] != null ? Timetoken(int.tryParse(object['o']['t'])) : null;
    originalRegion = object['o'] != null ? object['o']['r'] : null;
    timetoken =
        object['p'] != null ? Timetoken(int.tryParse(object['p']['t'])) : null;
    region = object['p'] != null ? object['p']['r'] : null;
    userMeta = object['u'];
    originalMessage = object;
  }
}

enum PresenceAction { join, leave, timeout, stateChange }

PresenceAction fromString(String action) => const {
      'join': PresenceAction.join,
      'leave': PresenceAction.leave,
      'timeout': PresenceAction.timeout,
      'state-change': PresenceAction.stateChange
    }[action];

class PresenceEvent {
  Envelope envelope;

  PresenceAction action;
  UUID uuid;
  int occupancy;
  Timetoken get timetoken => envelope.timetoken;

  PresenceEvent.fromEnvelope(this.envelope)
      : action = fromString(envelope.payload['action'] as String),
        uuid = UUID(envelope.payload['uuid'] as String),
        occupancy = envelope.payload['occupancy'] as int;
}
