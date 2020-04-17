import '../core.dart';
import 'request_type.dart';

typedef SignFunction = String Function(
    RequestType type,
    List<String> pathSegments,
    Map<String, String> queryParameters,
    Map<String, String> headers,
    String body);

class Request {
  static Map<String, String> defualtQueryParameters = {
    'pnsdk': 'PubNub-Dart/${Core.version}'
  };
  static final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json'
  };

  RequestType type;
  List<String> pathSegments;

  Map<String, String> queryParameters;
  Map<String, String> headers;
  String body;

  Request(this.type, this.pathSegments,
      {Map<String, String> queryParameters,
      Map<String, String> headers,
      String body,
      SignFunction signWith}) {
    pathSegments = pathSegments;
    this.queryParameters = {
      ...(queryParameters ?? {}),
      ...defualtQueryParameters
    };
    this.headers = {...(headers ?? {}), ...defaultHeaders};
    this.body = body;

    if (signWith != null) {
      this.queryParameters['signature'] = signWith(
          type, pathSegments, this.queryParameters, this.headers, this.body);
    }
  }
}

abstract class RequestHandler {
  Future<String> text();
  Future<Map<String, List<String>>> headers();

  bool isCancelled;
  void cancel([dynamic reason]);
}
