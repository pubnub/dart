import 'package:pubnub/src/core/keyset.dart';

extension FileKeysetExtension on Keyset {
  int get fileMessagePublishRetryLimit =>
      settings['#fileMessagePublishRetryLimit'] ?? 5;
  set fileMessagePublishRetryLimit(int retryCount) =>
      settings['#fileMessagePublishRetryLimit'] = retryCount;
}
