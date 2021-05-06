import 'request_type.dart';

/// @nodoc
class Request {
  RequestType type;
  Uri? uri;
  Map<String, String>? headers;
  Object? body;

  Request.get({this.uri, this.headers, this.body}) : type = RequestType.get;
  Request.post({this.uri, this.headers, this.body}) : type = RequestType.post;
  Request.patch({this.uri, this.headers, this.body}) : type = RequestType.patch;
  Request.delete({this.uri, this.headers, this.body})
      : type = RequestType.delete;
  Request.subscribe({this.uri, this.headers, this.body})
      : type = RequestType.subscribe;
  Request.file({this.uri, this.headers, this.body}) : type = RequestType.file;

  @override
  String toString() {
    return 'Request { [$type] $uri }';
  }
}
