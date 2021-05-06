import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart';

/// Represents a message received from a subscription.
///
/// {@category Results}
/// {@category Basic Features}
class Envelope extends BaseMessage {
  final String shard;
  final String? subscriptionPattern;
  final String channel;
  final int region;
  final MessageType messageType;
  final int flags;
  final UUID uuid;

  final Timetoken? originalTimetoken;
  final int? originalRegion;

  final dynamic? userMeta;

  dynamic get payload => content;

  Envelope._(
      {required dynamic content,
      required dynamic originalMessage,
      required Timetoken publishedAt,
      required this.shard,
      required this.subscriptionPattern,
      required this.channel,
      required this.messageType,
      required this.flags,
      required this.uuid,
      required this.originalTimetoken,
      required this.originalRegion,
      required this.region,
      required this.userMeta})
      : super(
          content: content,
          originalMessage: originalMessage,
          publishedAt: publishedAt,
        );

  /// @nodoc
  factory Envelope.fromJson(dynamic object) {
    return Envelope._(
      originalMessage: object,
      shard: object['a'] as String,
      subscriptionPattern: object['b'] as String?,
      channel: object['c'] as String,
      content: object['d'],
      messageType: MessageTypeExtension.fromInt(object['e']),
      flags: object['f'] as int,
      uuid: UUID(object['i'] ?? ''),
      originalTimetoken: object['o'] != null
          ? Timetoken(BigInt.parse(object['o']['t']))
          : null,
      originalRegion: object['o']?['r'],
      publishedAt: Timetoken(BigInt.parse(object['p']['t'])),
      region: object['p']['r'],
      userMeta: object['u'],
    );
  }
}

/// Represents a presence action.
enum PresenceAction {
  join,
  leave,
  timeout,
  stateChange,
  interval,

  /// Represents a presence action that is unrecognized by the SDK
  unknown,
}

/// @nodoc
extension PresenceActionExtension on PresenceAction {
  static PresenceAction fromString(String? action) {
    switch (action) {
      case 'join':
        return PresenceAction.join;
      case 'leave':
        return PresenceAction.leave;
      case 'timeout':
        return PresenceAction.timeout;
      case 'state-change':
        return PresenceAction.stateChange;
      case 'interval':
        return PresenceAction.interval;
      case null:
      default:
        return PresenceAction.unknown;
    }
  }
}

/// Represents an event in presence.
///
/// {@category Results}
class PresenceEvent {
  Envelope envelope;

  PresenceAction action;
  UUID? uuid;
  int occupancy;
  Timetoken get timetoken => envelope.publishedAt;

  List<UUID> get join => (envelope.payload['join'] as List<dynamic>? ?? [])
      .cast<String>()
      .map((uuid) => UUID(uuid))
      .toList();
  List<UUID> get leave => (envelope.payload['leave'] as List<dynamic>? ?? [])
      .cast<String>()
      .map((uuid) => UUID(uuid))
      .toList();

  PresenceEvent.fromEnvelope(this.envelope)
      : action = PresenceActionExtension.fromString(
            envelope.payload['action'] as String),
        uuid = envelope.payload['uuid'] != null
            ? UUID(envelope.payload['uuid'])
            : null,
        occupancy = envelope.payload['occupancy'] as int;
}
