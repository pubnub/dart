import 'package:pubnub/src/core/core.dart';

import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/signal.dart';

mixin SignalDx on Core {
  /// Publishes signal [message] to a [channel].
  Future<SignalResult> signal(String channel, dynamic message,
      {Keyset keyset, String using}) async {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    var payload = await super.parser.encode(message);
    var params = SignalParams(keyset, channel, payload);

    return defaultFlow(
        core: this,
        params: params,
        serialize: (object, [_]) => SignalResult.fromJson(object));
  }
}
