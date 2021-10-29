import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pubnub/core.dart';

String _encodeQueryParameters(Map<String, String> queryParameters) => SplayTreeMap
        .from(queryParameters)
    .entries
    .map((entry) =>
        '${entry.key}=${Uri.encodeQueryComponent(entry.value).replaceAll(RegExp(r"\+"), '%20')}')
    .join('&');

String computeSignature(Keyset keyset, List<String> pathSegments,
    Map<String, String> queryParameters) {
  var queryParams = _encodeQueryParameters(queryParameters);

  var plaintext = '''${keyset.subscribeKey}
${keyset.publishKey}
/${pathSegments.join('/')}
$queryParams''';

  var hmac = Hmac(sha256, utf8.encode(keyset.secretKey!));
  var digest = hmac.convert(utf8.encode(plaintext));
  var ciphertext = base64Url.encode(digest.bytes);

  return ciphertext;
}

String computeV2Signature(
    Keyset keyset,
    RequestType type,
    List<String> pathSegments,
    Map<String, String> queryParameters,
    String body) {
  var queryString = _encodeQueryParameters(
      {'pnsdk': 'PubNub-Dart/${Core.version}', ...queryParameters});

  var encodedPathSegments = <String>[];
  pathSegments.forEach(
      (component) => encodedPathSegments.add(Uri.encodeFull(component)));

  var plaintext = '''${type.method.toUpperCase()}
${keyset.publishKey}
/${encodedPathSegments.join('/')}
$queryString
${'$body' == 'null' ? '' : '$body'}''';

  var hmac = Hmac(sha256, utf8.encode(keyset.secretKey!));
  var digest = hmac.convert(utf8.encode(plaintext));
  var ciphertext = base64.encode(digest.bytes);

  return 'v2.$ciphertext'
      .replaceAll(RegExp(r'\+'), '-')
      .replaceAll(RegExp(r'\/'), '_')
      .replaceAll(RegExp(r'\=*$'), '');
}
