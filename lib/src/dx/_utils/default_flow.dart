import 'package:meta/meta.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

typedef Serialize<R> = R Function(dynamic object,
    [Map<String, List<String>> headers]);

Future<R> defaultFlow<P extends Parameters, R>(
    {@required Core core,
    @required P params,
    bool deserialize = true,
    @required Serialize<R> serialize}) async {
  var fiber = Fiber(core,
      action: () => _defaultFlow<P, R>(
          core: core,
          params: params,
          deserialize: deserialize,
          serialize: serialize));

  await fiber.run();

  return fiber.future;
}

Future<R> _defaultFlow<P extends Parameters, R>(
    {@required Core core,
    @required P params,
    bool deserialize = true,
    @required Serialize<R> serialize}) async {
  var request = params.toRequest();

  try {
    var handler = await core.networking.handler();
    var response = await handler.response(request);

    if (deserialize) {
      var result = await core.parser.decode(response.text);

      return serialize(result, response.headers);
    } else {
      return serialize(response);
    }
  } on PubNubRequestFailureException catch (exception) {
    var error = await core.parser.decode(exception.response.text,
        type: request.type == RequestType.file ? 'xml' : 'json');

    if (error is Map) {
      error = DefaultResult.fromJson(error);
    }

    throw getExceptionFromAny(error);
  }
}
