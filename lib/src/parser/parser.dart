import 'dart:convert';

import '../core/parse.dart';

class PubNubParserModule implements ParserModule {
  Future<dynamic> decode(String input) async {
    try {
      return json.decode(input);
    } catch (e) {
      throw ParserException('Cannot decode string as JSON');
    }
  }

  Future<String> encode(dynamic input) async {
    try {
      return json.encode(input);
    } on JsonUnsupportedObjectError catch (error) {
      throw ParserException(
          'Cannot encode object ${error.unsupportedObject} as JSON String');
    }
  }
}
