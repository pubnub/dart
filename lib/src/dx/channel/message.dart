import 'package:pubnub/core.dart';

/// Represents a message in [ChannelHistory] and [PaginatedChannelHistory].
///
/// {@category Results}
class Message {
  /// Contents of the message.
  dynamic contents;

  /// Original timetoken.
  Timetoken timetoken;

  Message();

  /// @nodoc
  factory Message.fromJson(Map<String, dynamic> object) {
    return Message()
      ..contents = object['message']
      ..timetoken = Timetoken(object['timetoken']);
  }
}
