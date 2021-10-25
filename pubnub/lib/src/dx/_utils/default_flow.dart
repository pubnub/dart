import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/pam/extensions/keyset.dart';

typedef Serialize<R> = R Function(dynamic object,
    [Map<String, List<String>>? headers]);

Future<R> defaultFlow<P extends Parameters, R>({
  required Core core,
  required P params,
  bool deserialize = true,
  required Serialize<R> serialize,
  Keyset? keyset,
}) async {
  var fiber = Fiber(
    core,
    action: () => _defaultFlow<P, R>(
      core: core,
      params: params,
      deserialize: deserialize,
      serialize: serialize,
      keyset: keyset,
    ),
  );

  await fiber.run();

  return fiber.future;
}

Future<R> _defaultFlow<P extends Parameters, R>({
  required Core core,
  required P params,
  bool deserialize = true,
  required Serialize<R> serialize,
  Keyset? keyset,
}) async {
  var request = params.toRequest();

  if (keyset != null && request.uri?.authority == '') {
    request.uri = request.uri?.replace(
      queryParameters: {
        ...request.uri?.queryParameters ?? {},
        'uuid': keyset.uuid.value,
        if (keyset.hasAuth() && !request.uri!.pathSegments.contains('grant'))
          'auth': keyset.getAuth(),
      },
    );
  }

  if (keyset != null &&
      keyset.secretKey != null &&
      (request.body is String || request.body == null)) {
    request.uri = request.uri?.replace(queryParameters: {
      ...request.uri!.queryParameters,
      'timestamp': '${Time().now()!.millisecondsSinceEpoch ~/ 1000}',
    });

    var signature = computeV2Signature(
      keyset,
      request.type,
      request.uri!.pathSegments,
      request.uri!.queryParameters,
      '${request.body}',
    );

    request.uri = request.uri?.replace(queryParameters: {
      ...request.uri!.queryParameters,
      'signature': signature
    });
  }

  try {
    var handler = await core.networking.handler();
    var response = await handler.response(request);

    if (deserialize) {
      var result = await core.parser.decode(response.text);

      return serialize(result, response.headers);
    } else {
      return serialize(response);
    }
  } on RequestFailureException catch (exception) {
    dynamic error;
    try {
      error = await core.parser.decode(exception.response.text,
          type: request.type == RequestType.file ? 'xml' : 'json');

      if (error is Map) {
        error = DefaultResult.fromJson(error);
      }
    } on ParserException {
      error = exception.response.text;
    }

    throw getExceptionFromAny(error);
  }
}
