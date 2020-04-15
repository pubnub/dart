import 'package:pubnub/src/core/keyset.dart';
import 'package:test/test.dart';

void main() {
  KeysetStore store;
  group('core [keyset]', () {
    group('#add', () {
      setUp(() {
        store = KeysetStore();
      });

      test('throws when adding two keys with the same name', () {
        store.add(Keyset(subscribeKey: 'test'), name: 'test');

        expect(() => store.add(Keyset(subscribeKey: 'test'), name: 'test'),
            throwsA(TypeMatcher<KeysetException>()));
      });
    });

    group('#get', () {
      setUp(() {
        store = KeysetStore();
        store.add(Keyset(subscribeKey: 'default'),
            name: 'default', useAsDefault: true);
      });

      test('throws if name is null and defaultIfNameIsNull is false', () {
        expect(() => store.get(null, defaultIfNameIsNull: false),
            throwsA(TypeMatcher<KeysetException>()));
      });

      test('throws if keyset name is not recognized', () {
        expect(
            () => store.get('some'), throwsA(TypeMatcher<KeysetException>()));
      });

      test('throws if name is null and default key is not defined', () {
        store.remove('default');
        expect(() => store.get(null, defaultIfNameIsNull: true),
            throwsA(TypeMatcher<KeysetException>()));
      });

      test('returns null instead of throwing if throwOnNull is false', () {
        expect(store.get(null, defaultIfNameIsNull: false, throwOnNull: false),
            equals(null));

        expect(store.get('some', throwOnNull: false), equals(null));

        store.remove('default');
        expect(store.get(null, defaultIfNameIsNull: true, throwOnNull: false),
            equals(null));
      });

      test('returns default keyset if name is null', () {
        expect(
            store.get(null, defaultIfNameIsNull: true),
            allOf(
                isA<Keyset>(),
                predicate(
                    (Keyset keyset) => keyset.subscribeKey == 'default')));
      });

      test('returns correct keyset if name is recognized', () {
        expect(
            store.get('default'),
            allOf(
                isA<Keyset>(),
                predicate(
                    (Keyset keyset) => keyset.subscribeKey == 'default')));
      });
    });
  });
}
