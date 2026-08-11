import 'package:pubnub/src/core/timetoken.dart';
import 'package:test/test.dart';

void main() {
  group('Timetoken.from', () {
    const literal = '17847152241442333';

    test('parses String values exactly', () {
      expect(Timetoken.from(literal).value, equals(BigInt.parse(literal)));
    });

    test('parses int values', () {
      expect(Timetoken.from(42).value, equals(BigInt.from(42)));
    });

    test('parses BigInt values', () {
      final value = BigInt.parse(literal);
      expect(Timetoken.from(value).value, equals(value));
    });

    test('parses stringified num values', () {
      expect(Timetoken.from(100).toString(), equals('100'));
    });
  });
}
