import 'dart:convert';
import 'dart:html';

import 'package:pubnub/core.dart';

class Response extends IResponse {
  final List<int> _bytes;
  final HttpRequest _request;

  Response(this._bytes, this._request);

  @override
  List<int> get byteList => _bytes;

  @override
  Map<String, List<String>> get headers {
    var headers = <String, List<String>>{};

    _request.responseHeaders.forEach((key, values) {
      headers[key] = [values];
    });

    return headers;
  }

  @override
  int get statusCode => _request.status ?? 400;

  @override
  String get text => utf8.decode(_bytes);
}
