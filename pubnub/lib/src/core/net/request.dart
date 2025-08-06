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
    var parts = [
      'Method: ${type.method}',
      'URL: $uri',
    ];
    if (headers != null && headers!.isNotEmpty) {
      parts.add('Headers:');
      headers!.forEach((key, value) {
        parts.add('  $key: $value');
      });
    }
    if (body != null) {
      if (body is List<int>) {
        parts.add(
            'Body: binary content with length ${(body as List<int>).length}');
      } else {
        parts.add('Body: $body');
      }
    }
    return '\n\t${parts.join('\n\t')}';
  }
}
