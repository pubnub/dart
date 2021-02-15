import 'dart:convert';
import 'dart:io';

import 'package:pubnub/core.dart';

class Response extends IResponse {
  final List<int> _bytes;
  final HttpClientResponse _response;

  Response(this._bytes, this._response);

  @override
  List<int> get byteList => _bytes;

  @override
  Map<String, List<String>> get headers {
    var headers = <String, List<String>>{};

    _response.headers.forEach((key, values) {
      headers[key] = values;
    });

    return headers;
  }

  @override
  int get statusCode => _response.statusCode;

  @override
  String get text => utf8.decode(_bytes);
}
