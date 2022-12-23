import '../uuid.dart';
import '../user_id.dart';
import '../crypto/cipher_key.dart';

/// Represents a configuration for a given subscribe key.
///
/// {@category Basic Features}
class Keyset {
  /// Subscribe key.
  final String subscribeKey;

  /// Unique identifier of this device.
  final UUID uuid;

  /// Unique identifier of this user.
  UserId get userId => UserId(uuid.value);

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
    @Deprecated('Use `userId` instead') UUID? uuid,
    UserId? userId,
    required this.subscribeKey,
    this.publishKey,
    this.secretKey,
    this.authKey,
    this.cipherKey,
  })  : assert((uuid == null) ^ (userId == null)),
        uuid = userId != null ? UUID(userId.value) : uuid!;
}
