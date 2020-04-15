import 'package:meta/meta.dart';

import '../core.dart';
import 'request_type.dart';

class Request {
  static Map<String, String> defualtQueryParameters = {
    'pnsdk': 'PubNub-Dart/${Core.version}'
  };
  static final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json'
  };

  RequestType type;
  Uri uri;
  Map<String, String> headers = {};
  String body = null;

  Request({@required this.type, @required this.uri, this.headers, this.body});

  @override
  String toString() => """($type) $uri""";
}

abstract class RequestHandler {
  Future<String> text();
  Future<Map<String, List<String>>> headers();

  bool isCancelled;
  void cancel([dynamic reason]);
}
