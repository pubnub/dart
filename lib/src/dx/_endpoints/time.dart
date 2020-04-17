import 'package:pubnub/src/core/core.dart';

class TimeParams extends Parameters {
  @override
  Request toRequest() {
    return Request(RequestType.get, ['time', '0']);
  }
}
