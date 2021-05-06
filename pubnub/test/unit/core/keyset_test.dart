import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

void main() {
  late KeysetStore store;
  group('Core [keyset]', () {
    group('#add', () {
      setUp(() {
        store = KeysetStore();
      });

      test('throws when adding two keys with the same name', () {
        store.add('test', Keyset(subscribeKey: 'test', uuid: UUID('test')));

        expect(
            () => store.add(
                'test', Keyset(subscribeKey: 'test', uuid: UUID('test'))),
            throwsA(TypeMatcher<KeysetException>()));
      });
    });

    group('#get', () {
      setUp(() {
        store = KeysetStore();
        store.add(
          'default',
          Keyset(subscribeKey: 'default', uuid: UUID('test')),
          useAsDefault: true,
        );
      });

      test('throws if keyset name is not recognized', () {
        expect(() => store['some'], throwsA(TypeMatcher<KeysetException>()));
      });

      test('throws if name is null and default key is not defined', () {
        store.remove('default');
        expect(() => store[null], throwsA(TypeMatcher<KeysetException>()));
      });

      test('returns default keyset if name is null', () {
        expect(
            store[null],
            allOf(
                isA<Keyset>(),
                predicate(
                    (Keyset keyset) => keyset.subscribeKey == 'default')));
      });

      test('returns correct keyset if name is recognized', () {
        expect(
            store['default'],
            allOf(
                isA<Keyset>(),
                predicate(
                    (Keyset keyset) => keyset.subscribeKey == 'default')));
      });
    });
  });
}
