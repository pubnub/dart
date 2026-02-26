import 'dart:convert';

import 'package:pubnub/core.dart';
import 'package:web/web.dart' as web;

class Response extends IResponse {
  final List<int> _bytes;
  final web.XMLHttpRequest _xhr;

  Response(this._bytes, this._xhr);

  @override
  List<int> get byteList => _bytes;

  @override
  Map<String, List<String>> get headers {
    var headers = <String, List<String>>{};

    var allHeaders = _xhr.getAllResponseHeaders();
    for (var line in allHeaders.split('\r\n')) {
      if (line.isEmpty) continue;
      var colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;
      var key = line.substring(0, colonIndex).trim().toLowerCase();
      var value = line.substring(colonIndex + 1).trim();
      headers[key] = [value];
    }

    return headers;
  }

  @override
  int get statusCode => _xhr.status;

  @override
  String get text => utf8.decode(_bytes);

  @override
  String toString() {
    var parts = [
      'URL: ${_xhr.responseURL}',
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
