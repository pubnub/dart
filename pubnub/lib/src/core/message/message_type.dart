/// Represents the type of a message.
///
/// {@category Basic Features}
enum MessageType { normal, signal, objects, messageAction, file }

/// @nodoc
extension MessageTypeExtension on MessageType {
  static MessageType fromInt(int? messageType) {
    switch (messageType) {
      case 1:
        return MessageType.signal;
      case 2:
        return MessageType.objects;
      case 3:
        return MessageType.messageAction;
      case 4:
        return MessageType.file;

      case 0:
      case null:
      default:
        return MessageType.normal;
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
    }
  }
}
