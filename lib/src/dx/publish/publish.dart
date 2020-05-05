import 'package:pubnub/src/core/core.dart';

import 'package:pubnub/src/dx/_endpoints/publish.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

final _logger = injectLogger('dx.publish');

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
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [InvariantException].
  Future<PublishResult> publish(String channel, dynamic message,
      {Keyset keyset, String using, bool storeMessage, int ttl}) async {
    Ensure(channel).isNotEmpty('channel name');
    Ensure(message).isNotNull('message');

    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset).isNotNull('keyset');

    var payload = await super.parser.encode(message);
    var params = PublishParams(keyset, channel, payload,
        storeMessage: storeMessage, ttl: ttl);

    _logger.verbose('Publishing a message to a channel $channel');

    return defaultFlow<PublishParams, PublishResult>(
        logger: _logger,
        core: this,
        params: params,
        serialize: (object, [_]) => PublishResult.fromJson(object));
  }
}
