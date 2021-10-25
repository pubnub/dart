import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class SignalParams extends Parameters {
  Keyset keyset;
  String channel;
  String payload;

  SignalParams(this.keyset, this.channel, this.payload);

  @override
  Request toRequest() {
    var pathSegments = <String>[
      'signal',
      keyset.publishKey!,
      keyset.subscribeKey,
      '0',
      channel,
      '0',
      payload
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
      'uuid': keyset.uuid.value,
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of signal endpoint call.
///
/// {@category Results}
class SignalResult extends Result {
  final bool isError;
  final String description;
  final int timetoken;

  SignalResult._(this.isError, this.description, this.timetoken);

  factory SignalResult.fromJson(dynamic object) {
    if (object is List) {
      return SignalResult._(
          object[0] == 1 ? false : true, object[1], int.parse(object[2]));
    }

    throw getExceptionFromDefaultResult(DefaultResult.fromJson(object));
  }
}
