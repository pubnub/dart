import 'package:pubnub/src/core/core.dart';

class TimeParams extends Parameters {
  Request toRequest() {
    return Request(
        type: RequestType.get, uri: Uri(pathSegments: ['time', '0']));
  }
}
