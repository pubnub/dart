/// Represents the type of a message.
///
/// {@category Basic Features}
enum MessageType {
  normal,
  signal,
  objects,
  messageAction,
  file,
  dataSync,

  /// Represents a message type that is unrecognized by the SDK.
  unknown
}

/// @nodoc
extension MessageTypeExtension on MessageType {
  static MessageType fromInt(int? messageType) {
    switch (messageType) {
      case null:
      case 0:
        return MessageType.normal;
      case 1:
        return MessageType.signal;
      case 2:
        return MessageType.objects;
      case 3:
        return MessageType.messageAction;
      case 4:
        return MessageType.file;
      case 5:
        return MessageType.dataSync;
      default:
        return MessageType.unknown;
    }
  }

  int toInt() {
    switch (this) {
      case MessageType.normal:
        return 0;
      case MessageType.signal:
        return 1;
      case MessageType.objects:
        return 2;
      case MessageType.messageAction:
        return 3;
      case MessageType.file:
        return 4;
      case MessageType.dataSync:
        return 5;
      case MessageType.unknown:
        return -1;
    }
  }
}
