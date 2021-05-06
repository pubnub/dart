import 'package:pubnub/src/core/parser.dart';
import 'package:pubnub/src/parser/parser.dart';

import 'package:test/test.dart';

void main() {
  late ParserModule parser;
  group('Parser [PubNubParserModule]', () {
    setUp(() {
      parser = ParserModule();
    });

    group('#decode', () {
      test('returns Map if json is an object', () async {
        var input = '{"hello": "world", "answer": 42}';

        expect(await parser.decode(input),
            allOf(equals({'hello': 'world', 'answer': 42}), isA<Map>()));
      });

      test('returns List if json is an array', () async {
        var input = '[1, 2, 3]';

        expect(
            await parser.decode(input), allOf(isA<List>(), equals([1, 2, 3])));
      });

      test('throws ParserException if cannot parse', () async {
        var input = 'inval[id]';

        expect(parser.decode(input), throwsA(TypeMatcher<ParserException>()));
      });
    });

    group('#encode', () {
      test('returns String if object is valid', () async {
        var input = {
          'hello': 'world',
          'int': 42,
          'float': 12.345789,
          'boolean': true,
          'list': [1, false, 'string'],
          'object': {'another': 'object'}
        };

        expect(await parser.encode(input), isA<String>());
      });

      test('throws ParserException if object is invalid', () async {
        var input = {'instance': parser};

        expect(parser.encode(input), throwsA(TypeMatcher<ParserException>()));
      });
    });
  });
}
