import 'dart:convert';

import 'package:pubnub/src/core/timetoken.dart';
import 'package:pubnub/src/parser/big_int_json_web.dart';
import 'package:test/test.dart';

void main() {
  group('quoteBigIntegers [web implementation]', () {
    test('quotes bare 17-digit integers', () {
      expect(
        quoteBigIntegers('[17847152241442333]'),
        equals('["17847152241442333"]'),
      );
    });

    test('quotes negative 16+ digit integers', () {
      expect(
        quoteBigIntegers('{"t":-17847152241442333}'),
        equals('{"t":"-17847152241442333"}'),
      );
    });

    test('leaves short integers alone', () {
      expect(quoteBigIntegers('[1, 42, 100]'), equals('[1, 42, 100]'));
      expect(
        quoteBigIntegers('{"answer":42,"count":999}'),
        equals('{"answer":42,"count":999}'),
      );
    });

    test('leaves already-quoted digit strings alone', () {
      final input = '{"timetoken":"17847152241442333"}';
      expect(quoteBigIntegers(input), equals(input));
    });

    test('does not quote digits inside JSON string values', () {
      final input = '{"message":"id=17847152241442333","ok":true}';
      expect(quoteBigIntegers(input), equals(input));
    });

    test('leaves floating point numbers alone', () {
      final input = '{"pi":3.141592653589793,"n":1.234567890123456}';
      expect(quoteBigIntegers(input), equals(input));
    });

    test('quotes multiple bare large integers in v2 history shape', () {
      final input =
          '[[{"message":"hello","timetoken":17847152241442333}],17847152241442333,17847152241442330]';
      final quoted = quoteBigIntegers(input);

      expect(
        quoted,
        equals(
          '[[{"message":"hello","timetoken":"17847152241442333"}],"17847152241442333","17847152241442330"]',
        ),
      );
    });

    test('preserves exact value through json.decode + Timetoken.from', () {
      const literal = '17847152241442333';
      final decoded = json.decode(quoteBigIntegers('[$literal]')) as List;

      expect(decoded[0], equals(literal));
      expect(decoded[0], isA<String>());
      expect(Timetoken.from(decoded[0]).value, equals(BigInt.parse(literal)));
    });

    test('plain json.decode loses precision for the same literal', () {
      const literal = '17847152241442333';
      // Documents why quoting is required on JS-backed runtimes. On the Dart
      // VM this may still be exact; the assert only runs when precision is lost.
      final decoded = json.decode('[$literal]') as List;
      final viaString = '${decoded[0]}';
      if (viaString != literal) {
        expect(Timetoken.from(decoded[0]).value,
            isNot(equals(BigInt.parse(literal))));
        expect(Timetoken.from(json.decode(quoteBigIntegers('[$literal]'))[0])
            .value,
            equals(BigInt.parse(literal)));
      }
    });
  });
}
