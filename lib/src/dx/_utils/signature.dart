import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pubnub/src/core/core.dart';

String encodeString(String paramValue) =>
    Uri.encodeComponent(paramValue).replaceAllMapped(
        RegExp(r"/[!~*'()]/g"),
        (str) =>
            '%${str.group(0).codeUnitAt(0).toRadixString(16).toUpperCase()}');

String computeSignature(Keyset keyset, RequestType requestType,
    Map<String, String> queryParameters, List<String> pathSegments,
    {String payload}) {
  Set<String> queryString = <String>{};
  var sortedMap = Map.fromEntries(queryParameters.entries.toList()
    ..sort((e1, e2) => e1.key.compareTo(e2.key)));
  sortedMap.forEach((paramKey, paramValue) =>
      queryString.add('$paramKey=${encodeString(paramValue)}'));
  var signString =
      '${requestType.method}\n${keyset.publishKey}\n${pathSegments.join('/')}\n${queryString.join('&')}\n';
  if ((requestType.method == 'POST' || requestType.method == 'PATCH') &&
      payload != null) {
    signString += payload;
  }
  var signature = 'v2.${hmacSHA256(signString, keyset.authKey)}';
  signature = signature.replaceAll(RegExp(r"/\+/g"), '-');
  signature = signature.replaceAll(RegExp(r"/\//g"), '_');
  signature = signature.replaceAll(RegExp(r"/=+$/"), '');
  return signature;
}

String hmacSHA256(String input, String encriptionKey) {
  var key = utf8.encode(encriptionKey);
  var bytes = utf8.encode(input);

  var hmacSha256 = new Hmac(sha256, key); // HMAC-SHA256
  var digest = hmacSha256.convert(bytes);
  return '$digest';
}
