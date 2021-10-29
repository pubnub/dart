import 'package:pubnub/core.dart';

/// @nodoc
extension PamKeysetExtension on Keyset {
  /// Check for non-null `auth` parameter value.
  bool hasAuth() {
    return authKey != null || token != null;
  }

  /// Get `auth` parameter value.
  /// It is recommended to check for non-null value of token or authKey beforehand
  /// by calling `hasAuth()`.
  String getAuth() {
    return token ?? authKey!;
  }

  /// Get the token string.
  String? get token => settings['#token'];

  /// Set the token string received by sending grantToken request.
  set token(String? value) => settings['#token'] = value;
}
