import 'dart:convert';
import 'package:xml/xml.dart' show XmlDocument;

import 'package:pubnub/core.dart';

import '../core/parser.dart';

/// @nodoc
abstract class Parser<T> {
  Future<T> decode(String input);
  Future<String> encode(T input);

  const Parser();
}

class _JsonParser extends Parser<dynamic> {
  const _JsonParser();

  @override
  Future decode(String input) async {
    return json.decode(input);
  }

  @override
  Future<String> encode(input) async {
    return json.encode(input);
  }
}

class _XmlParser extends Parser<XmlDocument> {
  const _XmlParser();

  @override
  Future<XmlDocument> decode(String input) async {
    return XmlDocument.parse(input);
  }

  @override
  Future<String> encode(XmlDocument input) async {
    return input.toXmlString();
  }
}

const Map<String, Parser> _parserMap = {
  'json': _JsonParser(),
  'xml': _XmlParser(),
};

/// @nodoc
class ParserModule implements IParserModule {
  @override
  Future<T> decode<T>(String input, {String type = 'json'}) async {
    if (!_parserMap.containsKey(type)) {
      throw ParserException('Unsupported format $type.');
    }

    try {
      return await _parserMap[type]!.decode(input);
    } catch (e) {
      throw ParserException('Cannot decode input string as $type.', e);
    }
  }

  @override
  Future<String> encode<T>(T input, {String type = 'json'}) async {
    if (!_parserMap.containsKey(type)) {
      throw ParserException('Unsupported format $type.');
    }

    try {
      return await _parserMap[type]!.encode(input);
    } catch (e) {
      throw ParserException('Cannot encode input object as $type.', e);
    }
  }

  @override
  void register(Core core) {}
}
