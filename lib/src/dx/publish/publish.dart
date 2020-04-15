import 'package:logging/logging.dart';

import 'package:pubnub/src/core/core.dart';

import 'package:pubnub/src/dx/_endpoints/publish.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

final log = Logger('pubnub.dx.publish');

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
      {Keyset keyset,
      String using,
      bool storeMessage = null,
      int ttl = null}) async {
    Ensure(channel).isNotEmpty("Channel name cannot be empty");
    Ensure(message).isNotNull("Message cannot be null");

    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");

    var payload = await super.parser.encode(message);
    var params = PublishParams(keyset, channel, payload,
        storeMessage: storeMessage, ttl: ttl);

    return defaultFlow<PublishParams, PublishResult>(
        log: log,
        core: this,
        params: params,
        serialize: (object, [_]) => PublishResult.fromJson(object));
  }
}
