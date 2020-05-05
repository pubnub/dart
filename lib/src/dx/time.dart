import 'package:pubnub/src/core/core.dart';

import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/time.dart';

final _logger = injectLogger('pubnub.dx.time');

mixin TimeDx on Core {
  /// Get current timetoken value from the PubNub network.
  Future<Timetoken> time() async {
    return defaultFlow<TimeParams, Timetoken>(
        logger: _logger,
        core: this,
        params: TimeParams(),
        serialize: (object, [_]) => Timetoken(object[0] as int));
  }
}
