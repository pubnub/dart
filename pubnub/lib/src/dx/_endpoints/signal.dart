import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class SignalParams extends Parameters {
  Keyset keyset;
  String channel;
  String payload;

  SignalParams(this.keyset, this.channel, this.payload);

  @override
  Request toRequest() {
    var pathSegments = [
      'signal',
      keyset.publishKey,
      keyset.subscribeKey,
      '0',
      channel,
      '0',
      payload
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (keyset.uuid != null) 'uuid': keyset.uuid.value,
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of signal endpoint call.
///
/// {@category Results}
class SignalResult extends Result {
  bool isError;
  String description;
  int timetoken;

  SignalResult();

  factory SignalResult.fromJson(dynamic object) {
    if (object is List) {
      return SignalResult()
        ..timetoken = int.tryParse(object[2])
        ..description = object[1]
        ..isError = object[0] == 0 ? false : true;
    }

    throw getExceptionFromDefaultResult(DefaultResult.fromJson(object));
  }
}
