import 'package:pubnub/core.dart';

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
  final String? customMessageType;

  final Timetoken? originalTimetoken;
  final int? originalRegion;

  final dynamic userMeta;

  @override
  PubNubException? error;

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
      required this.userMeta,
      required this.customMessageType,
      this.error})
      : super(
            content: content,
            originalMessage: originalMessage,
            publishedAt: publishedAt,
            error: error);

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
      customMessageType: object['cmt'] as String?,
      originalTimetoken:
          object['o'] != null ? Timetoken.from(object['o']['t']) : null,
      originalRegion: object['o']?['r'],
      publishedAt: Timetoken.from(object['p']['t']),
      region: object['p']['r'],
      userMeta: object['u'],
      error: object['error'],
    );
  }
}
