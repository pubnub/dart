import 'package:pubnub/core.dart';

class TimeParams extends Parameters {
  Map<String, dynamic> toJson() {
    return {};
  }

  @override
  Request toRequest() {
    return Request.get(uri: Uri(pathSegments: ['time', '0']));
  }
}
