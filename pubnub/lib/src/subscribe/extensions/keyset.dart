import 'package:pubnub/core.dart';

/// @nodoc
extension SubscribeKeysetExtension on Keyset {
  /// Get filter expression for subscribe message filtering.
  String? get filterExpression => settings['#filterExpression'];

  /// Set filter expression for subscribe message filtering.
  set filterExpression(String? value) => settings['#filterExpression'] = value;

  /// Get interval at which heartbeats should be sent.
  int? get heartbeatInterval => settings['#heartbeatInterval'];

  /// Set interval at which heartbeats should be sent.
  set heartbeatInterval(int? value) => settings['#heartbeatInterval'] = value;
}
