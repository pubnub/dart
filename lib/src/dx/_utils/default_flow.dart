import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/net/exceptions.dart';

typedef Serialize<R> = R Function(dynamic object,
    [Map<String, List<String>> headers]);

Future<R> defaultFlow<P extends Parameters, R>(
    {@required Logger log,
    @required Core core,
    @required P params,
    @required Serialize<R> serialize}) async {
  var request = params.toRequest();

  try {
    var handler = await core.networking.handle(request);

    var response = await handler.text();
    var headers = await handler.headers();

    var object = await core.parser.decode(response);
    var result = serialize(object, headers);

    return result;
  } on PubNubRequestFailureException catch (exception) {
    var error = await core.parser.decode(exception.responseData);

    if (error is Map) {
      error = DefaultResult.fromJson(error);
    }

    throw getExceptionFromAny(error);
  }
}
