import '../core.dart';
import 'request.dart';
import 'response.dart';

abstract class IRequestHandler {
  static final Uri defaultUri = Uri(
      scheme: 'https',
      host: 'ps.pndsn.com',
      queryParameters: {'pnsdk': 'PubNub-Dart/${Core.version}'});

  static final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json'
  };

  Future<IResponse> response(Request request);

  Uri prepareUri(Uri requestUri) {
    return defaultUri.replace(
        scheme: requestUri.hasScheme ? requestUri.scheme : defaultUri.scheme,
        host: requestUri.host != '' ? requestUri.host : null,
        path: requestUri.path != '' ? requestUri.path : null,
        port: requestUri.hasPort ? requestUri.port : defaultUri.port,
        queryParameters: {
          if (requestUri.host == '') ...defaultUri.queryParameters,
          ...requestUri.queryParameters
        },
        userInfo: requestUri.userInfo);
  }

  bool isCancelled;
  void cancel([dynamic reason]);
}
