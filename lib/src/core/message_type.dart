/// Represents the type of a message.
///
/// {@category Basic Features}
enum MessageType { normal, signal, objects, messageAction, file }

/// @nodoc
extension MessageTypeExtension on MessageType {
  static MessageType fromInt(int messageType) => const {
        null: MessageType.normal,
        1: MessageType.signal,
        2: MessageType.objects,
        3: MessageType.messageAction,
        4: MessageType.file
      }[messageType];

  int toInt() => const {
        MessageType.normal: null,
        MessageType.signal: 1,
        MessageType.objects: 2,
        MessageType.messageAction: 3,
        MessageType.file: 4,
      }[this];
}
