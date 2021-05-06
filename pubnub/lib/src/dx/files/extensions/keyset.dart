import '../../../core/keyset/keyset.dart' show Keyset;

/// @nodoc
extension FileKeysetExtension on Keyset {
  int get fileMessagePublishRetryLimit =>
      settings['#fileMessagePublishRetryLimit'] ?? 5;
  set fileMessagePublishRetryLimit(int retryCount) =>
      settings['#fileMessagePublishRetryLimit'] = retryCount;
}
