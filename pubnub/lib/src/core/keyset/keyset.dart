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
  ///
  /// Prefer configuring encryption on the `PubNub` instance with an AES-CBC
  /// cryptor instead of setting a `cipherKey` here (which uses the legacy
  /// cryptor). See [Keyset.new] for details.
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
    @Deprecated(
        'Providing a cipherKey on Keyset uses the legacy cryptor. Configure '
        'encryption on the PubNub instance with an AES-CBC cryptor instead, '
        'e.g. PubNub(crypto: CryptoModule.aesCbcCryptoModule('
        'CipherKey.fromUtf8("your-cipher-key")), defaultKeyset: ...). '
        'This parameter will be removed in a future release.')
    this.cipherKey,
  })  : assert((uuid == null) ^ (userId == null)),
        uuid = userId != null ? UUID(userId.value) : uuid!;

  @override
  String toString() {
    var parts = [
      'Subscribe Key: $subscribeKey',
      'Publish Key: ${publishKey ?? 'not provided'}',
      'Secret Key: ${secretKey != null ? 'provided' : 'not provided'}',
      'User ID: $userId',
      'Auth Key: ${authKey != null ? 'provided' : 'not provided'}',
      'Cipher Key: ${cipherKey != null ? 'provided' : 'not provided'}'
    ];
    if (settings.isNotEmpty) {
      // `settings` can hold sensitive values (e.g. the PAM access token stored
      // under the `#token` key by the PAM extension), so never print raw
      // values here. Emit only the setting names.
      parts.add('Settings: ${settings.keys.toList()}');
    }
    return '\n\t    ${parts.join('\n\t    ')}';
  }
}
