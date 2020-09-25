import 'package:pubnub/src/core/keyset.dart';

/// @nodoc
extension SubscribeKeysetExtension on Keyset {
  String get filterExpression => settings['#filterExpression'];

  /// Set filter expression for subscribe message filtering.
  set filterExpression(String value) => settings['#filterExpression'] = value;
}
