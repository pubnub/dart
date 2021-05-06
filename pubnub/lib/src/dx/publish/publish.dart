import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/publish.dart';

export '../_endpoints/publish.dart';

final _logger = injectLogger('pubnub.dx.publish');

mixin PublishDx on Core {
  /// Publishes [message] to a [channel].
  ///
  /// You can override the default account configuration on message
  /// saving using [storeMessage] flag - `true` to save and `false` to discard.
  /// Leave this option unset if you want to use the default.
  ///
  /// You can set a per-message time to live in storage using [ttl] option.
  /// If set to `0`, message won't expire.
  /// If unset, expiration will fall back to default.
  ///
  /// [meta] parameter is for providing additional information with message
  /// that can be used for stream filtering
  /// * Inorder to make stream filtering work, Provide valid `Object` as meta.
  /// * Invalid type (e.g String) data won't be passed to server.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  ///
  /// Example:
  /// ```dart
  /// var result = await pubnub.publish('my-ch', 'message');
  /// ```
  Future<PublishResult> publish(String channel, dynamic message,
      {Keyset? keyset,
      String? using,
      dynamic meta,
      bool? storeMessage,
      int? ttl}) async {
    Ensure(channel).isNotEmpty('channel name');
    Ensure(message).isNotNull('message');

    keyset ??= keysets[using];
    Ensure(keyset.publishKey).isNotNull('publishKey');

    var payload = await super.parser.encode(message);

    if (keyset.cipherKey != null) {
      payload =
          await super.parser.encode(crypto.encrypt(keyset.cipherKey!, payload));
    }

    var params = PublishParams(keyset, channel, payload,
        storeMessage: storeMessage, ttl: ttl);

    if (meta != null && !(meta is String)) {
      params.meta = await super.parser.encode(meta);
    }

    _logger.verbose('Publishing a message to a channel $channel');

    return await defaultFlow<PublishParams, PublishResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => PublishResult.fromJson(object));
  }
}
