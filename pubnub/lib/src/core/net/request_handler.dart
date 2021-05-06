import 'request.dart';
import 'response.dart';

abstract class IRequestHandler {
  Future<IResponse> response(Request request);

  Uri prepareUri(Uri baseUri, Uri requestUri) {
    return baseUri.replace(
      scheme: requestUri.hasScheme ? requestUri.scheme : baseUri.scheme,
      host: requestUri.host != '' ? requestUri.host : null,
      path: requestUri.path != '' ? requestUri.path : null,
      port: requestUri.hasPort ? requestUri.port : baseUri.port,
      queryParameters: {
        if (requestUri.host == '') ...baseUri.queryParameters,
        ...requestUri.queryParameters
      },
      userInfo: requestUri.userInfo,
    );
  }

  bool get isCancelled;
  void cancel([dynamic reason]);
}
