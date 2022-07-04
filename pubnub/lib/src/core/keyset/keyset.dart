import '../uuid.dart';
import '../userId.dart';
import '../crypto/cipher_key.dart';

/// Represents a configuration for a given subscribe key.
///
/// {@category Basic Features}
class Keyset {
  /// Subscribe key.
  final String subscribeKey;

  /// Unique identifier of this device.
  ///
  /// Please provide [userId] instead. To uniquely identify a PubNub user.
  @deprecated
  UUID? uuid;

  /// Unique Id for user.
  ///
  /// Note: Keyset initialisation with both [uuid] and [userId] values is not allowed.
  final UserId? userId;

  /// Publish key.
  final String? publishKey;

  /// Secret key used for administrative tasks.
  final String? secretKey;

  /// Used for message encryption.
  final CipherKey? cipherKey;

  /// If PAM is enabled, authentication key is required to access channels.
  String? authKey;

  /// A map of settings that can be set and used by specific DX extensions.
  Map<String, dynamic> settings = {};

  Keyset({
    required this.subscribeKey,
    @deprecated this.uuid,
    this.userId,
    this.publishKey,
    this.secretKey,
    this.authKey,
    this.cipherKey,
  }) : assert(
            (uuid != null && userId == null) ||
                (uuid == null && userId != null),
            'Please provide either `uuid` or `userId` parameter value. Both values are not allowed together.') {
    if (userId != null) {
      // ignore: deprecated_member_use_from_same_package
      uuid = UUID(userId!.value);
    }
  }
}
