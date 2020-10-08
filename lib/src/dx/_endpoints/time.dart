import 'package:pubnub/core.dart';

class TimeParams extends Parameters {
  @override
  Request toRequest() {
    return Request.get(uri: Uri(pathSegments: ['time', '0']));
  }
}
