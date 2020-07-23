import '../core.dart';
import 'request_type.dart';

typedef SignFunction = String Function(
    RequestType type,
    List<String> pathSegments,
    Map<String, String> queryParameters,
    Map<String, String> headers,
    String body);

class Request {
  static Map<String, String> defaultQueryParameters = {
    'pnsdk': 'PubNub-Dart/${Core.version}'
  };
  static final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json'
  };

  RequestType type;
  List<String> pathSegments;

  Map<String, String> queryParameters;
  Map<String, String> headers;
  dynamic body;
  Uri url;

  Request(this.type, this.pathSegments,
      {Map<String, String> queryParameters,
      Map<String, String> headers,
      dynamic body,
      SignFunction signWith,
      this.url}) {
    pathSegments = pathSegments;
    this.queryParameters = {
      ...(queryParameters ?? {}),
      ...defaultQueryParameters
    };
    this.headers = {...(headers ?? {}), ...defaultHeaders};
    this.body = body;

    if (signWith != null) {
      this.queryParameters['signature'] = signWith(
          type, pathSegments, this.queryParameters, this.headers, this.body);
    }
  }

  @override
  String toString() {
    return '${type.method} - $pathSegments?$queryParameters';
  }
}

abstract class RequestHandler {
  Future<dynamic> text();
  Future<Map<String, List<String>>> headers();
  Future<dynamic> response();

  bool isCancelled;
  void cancel([dynamic reason]);
}
