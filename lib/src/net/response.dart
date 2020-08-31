import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:pubnub/src/core/core.dart';

class Response extends IResponse {
  @override
  final Map<String, List<String>> headers;

  @override
  final int statusCode;

  final List<int> _data;

  Response(dio.Response<List<int>> response)
      : headers = response.headers.map,
        statusCode = response.statusCode,
        _data = response.data;

  @override
  String get text => utf8.decode(_data);

  @override
  List<int> get byteList => _data;
}
