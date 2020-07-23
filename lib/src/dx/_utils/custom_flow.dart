import 'package:meta/meta.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/net/exceptions.dart';

Future<R> customFlow<P extends Parameters, R>(
    {@required ILogger logger,
    @required Core core,
    @required P params,
    @required Serialize<R> serialize}) async {
  var request = params.toRequest();

  try {
    var handler = await core.networking.handleCustomRequest(request);

    var response = await handler.response();
    var headers = await handler.headers();

    var result = serialize(response, headers);

    return result;
  } on PubNubRequestFailureException catch (exception) {
    var error = await core.parser.decode(exception.responseData);

    if (error is Map) {
      error = DefaultResult.fromJson(error);
    }

    throw getExceptionFromAny(error);
  }
}
