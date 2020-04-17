import 'package:logging/logging.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_endpoints/time.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

final _log = Logger('pubnub.dx.time');

mixin TimeDx on Core {
  /// Get current timetoken value from the PubNub network.
  Future<Timetoken> time() async {
    return defaultFlow<TimeParams, Timetoken>(
        log: _log,
        core: this,
        params: TimeParams(),
        serialize: (object, [_]) => Timetoken(object[0] as int));
  }
}
