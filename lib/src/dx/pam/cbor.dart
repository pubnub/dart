import 'dart:convert';
import 'package:cbor/cbor.dart';
import 'package:typed_data/typed_data.dart';

import 'package:pubnub/src/core/core.dart';

import '../pam/pam.dart' show Permissions;

Token decode(String token) {
  final cbor = Cbor();
  final decoder = Utf8Decoder();
  var padding = '';
  if (token.length % 4 == 3) {
    padding = '=';
  } else if (token.length % 4 == 2) {
    padding = '==';
  }
  String clean = token.replaceAll('_', '/').replaceAll('-', '+') + padding;
  var payload = base64Decode(clean);
  cbor.decodeFromList(payload);
  var cborResult = cbor.getDecodedData();
  var result = cborResult[0].map(
      (key, value) => MapEntry(decoder.convert(key), _parse(value, decoder)));
  var tokenObject = Token.fromJson(result);
  tokenObject.resources = parsePermissions(tokenObject.resources);
  tokenObject.patterns = parsePermissions(tokenObject.patterns);
  return tokenObject;
}

dynamic _parse(dynamic data, Utf8Decoder decoder) {
  var decoder = Utf8Decoder();
  if (data is int) return data;
  if (data is Map)
    return data.map((key, value) => MapEntry(
        (key is String) ? key : decoder.convert(key), _parse(value, decoder)));
  return data;
}

class Token {
  int _version;
  Timetoken _timestamp;
  int _timeToLive;
  dynamic _resources;
  dynamic _patterns;
  dynamic _tokenMetadata;
  Uint8Buffer _signature;

  int get version => _version;
  Timetoken get timestamp => _timestamp;
  int get timeToLive => _timeToLive;
  Map<String, dynamic> get resources => _resources;
  set resources(Map<String, dynamic> resources) => _resources = resources;
  Map<String, dynamic> get patterns => _patterns;
  set patterns(Map<String, dynamic> patterns) => _patterns = patterns;
  dynamic get tokenMetadata => _tokenMetadata;
  Uint8Buffer get signature => _signature;

  Token();

  factory Token.fromJson(dynamic object) {
    return Token()
      .._version = object['v']
      .._timestamp = Timetoken(object['t'] as int)
      .._timeToLive = object['ttl']
      .._resources = object['res']
      .._patterns = object['pat']
      .._tokenMetadata = object['meta']
      .._signature = object['sig'];
  }
}

parsePermissions(Map<String, dynamic> resources) {
  return resources.map((resourceType, resource) => MapEntry(
      resourceType,
      resource.map(
          (id, permission) => MapEntry(id, Permissions.fromInt(permission)))));
}
