import 'package:pubnub/core.dart';

import './_utils/utils.dart';
import './_endpoints/time.dart';

mixin TimeDx on Core {
  /// Get current timetoken value from the PubNub network.
  Future<Timetoken> time() async {
    return defaultFlow<TimeParams, Timetoken>(
        core: this,
        params: TimeParams(),
        serialize: (object, [_]) => Timetoken(BigInt.from(object[0] as int)));
  }
}
