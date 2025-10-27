import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/signal.dart';

export '../_endpoints/signal.dart';

final _logger = injectLogger('pubnub.dx.signal');

mixin SignalDx on Core {
  /// Publishes signal [message] to a [channel].
  Future<SignalResult> signal(String channel, dynamic message,
      {String? customMessageType, Keyset? keyset, String? using}) async {
    _logger.silly('Signal API call');
    keyset ??= keysets[using];
    Ensure(keyset.publishKey).isNotNull('publishKey');

    var payload = await super.parser.encode(message);
    var params = SignalParams(keyset, channel, payload,
        customMessageType: customMessageType);
    _logger.fine(LogEvent(
        message: 'Signal API call with parameters:',
        details: params,
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => SignalResult.fromJson(object));
  }
}
