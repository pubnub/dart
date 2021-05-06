import 'dart:convert' show base64, base64Url, utf8;

import 'package:cbor/cbor.dart';

Map<dynamic, dynamic> parseToken(String base64UrlEncodedToken) {
  final length = base64UrlEncodedToken.length;

  var padding = '';
  if (length % 4 == 3) {
    padding = '=';
  } else if (length % 4 == 2) {
    padding = '==';
  }

  final decodedToken = base64Url.decode(base64UrlEncodedToken + padding);

  final instance = Cbor()..decodeFromList(decodedToken);
  var data = instance.getDecodedData()!.cast<Map>();
  var tokenData = data.first.cast<List, dynamic>();

  Map<String, dynamic> decodeMap(Map input) {
    return input.map((encodedKey, encodedValue) {
      var key = encodedKey is String ? encodedKey : utf8.decode(encodedKey);

      if (encodedValue is Map) {
        return MapEntry(key, decodeMap(encodedValue));
      } else if (encodedValue is List<int>) {
        return MapEntry(key, base64.encode(encodedValue));
      } else {
        return MapEntry(key, encodedValue);
      }
    });
  }

  return decodeMap(tokenData);
}
