import 'package:pubnub/core.dart';

import './_utils/utils.dart';
import './_endpoints/time.dart';

final _logger = injectLogger('pubnub.dx.time');

mixin TimeDx on Core {
  /// Get current timetoken value from the PubNub network.
  Future<Timetoken> time() async {
    _logger.info('Time API call');
    _logger.fine(LogEvent(
        message: 'Time API call with parameters:',
        details: {},
        detailsType: LogEventDetailsType.apiParametersInfo));

    return defaultFlow<TimeParams, Timetoken>(
        core: this,
        params: TimeParams(),
        serialize: (object, [_]) => Timetoken(BigInt.parse('${object[0]}')));
  }
}
