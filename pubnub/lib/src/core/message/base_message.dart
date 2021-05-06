import 'package:pubnub/core.dart';

/// Represents a base message.
///
/// Used as a base class for the messages hierarchy.
/// {@category Basic Features}
class BaseMessage {
  /// Timetoken at which the server accepted the message.
  final Timetoken publishedAt;

  /// Actual content of the message.
  final dynamic content;

  /// Original JSON message received from the server.
  final dynamic originalMessage;

  /// Alias for `publishedAt`.
  @deprecated
  Timetoken get timetoken => publishedAt;

  /// Alias for `content`.
  @deprecated
  dynamic get message => content;

  const BaseMessage({
    required this.publishedAt,
    required this.content,
    required this.originalMessage,
  });
}
