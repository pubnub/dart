import 'dart:convert';
import 'dart:io';

import 'package:pubnub/core.dart';

class Response extends IResponse {
  final List<int> _bytes;

  @override
  final int statusCode;

  @override
  final Map<String, List<String>> headers;

  Response._(this._bytes, this.statusCode, this.headers);

  /// Builds a [Response] from a `dart:io` [HttpClientResponse] (HTTP/1.1 path).
  factory Response.fromHttpClientResponse(
      List<int> bytes, HttpClientResponse response) {
    var headers = <String, List<String>>{};

    response.headers.forEach((key, values) {
      headers[key] = values;
    });

    return Response._(bytes, response.statusCode, headers);
  }

  /// Builds a [Response] from an HTTP/2 stream's status code and headers.
  ///
  /// [headers] must already have HTTP/2 pseudo-headers (such as `:status`)
  /// stripped out so the exposed map matches the HTTP/1.1 shape.
  factory Response.fromHttp2(
          List<int> bytes, int statusCode, Map<String, List<String>> headers) =>
      Response._(bytes, statusCode, headers);

  @override
  List<int> get byteList => _bytes;

  @override
  String get text => utf8.decode(_bytes);

  @override
  String toString() {
    var parts = [
      'Status Code: $statusCode',
    ];
    if (headers.containsKey('server')) {
      parts.add('Body: binary content length ${byteList.length}');
    } else {
      parts.add('Body: $text');
    }
    return '\n\t${parts.join('\n\t')}';
  }
}
