import 'package:test/test.dart';

import 'package:pubnub/src/dx/datasync/schema.dart';

void main() {
  group('DataSync JSON Patch buildJsonPatch', () {
    test('maps add / replace / remove', () {
      expect(
          buildJsonPatch(
              add: {'/payload/phone': '+15550100'},
              replace: {'/payload/creditScore': 810},
              remove: ['/payload/city']),
          equals([
            {'op': 'add', 'path': '/payload/phone', 'value': '+15550100'},
            {'op': 'replace', 'path': '/payload/creditScore', 'value': 810},
            {'op': 'remove', 'path': '/payload/city'},
          ]));
    });

    test('maps move with a from pointer', () {
      expect(
          buildJsonPatch(move: [
            JsonPointerPair(
                from: '/payload/legacyName', path: '/payload/displayName')
          ]),
          equals([
            {
              'op': 'move',
              'from': '/payload/legacyName',
              'path': '/payload/displayName'
            }
          ]));
    });

    test('maps copy with a from pointer', () {
      expect(
          buildJsonPatch(copy: [
            JsonPointerPair(
                from: '/payload/displayName', path: '/payload/previousName')
          ]),
          equals([
            {
              'op': 'copy',
              'from': '/payload/displayName',
              'path': '/payload/previousName'
            }
          ]));
    });

    test('maps test with an expected value', () {
      expect(
          buildJsonPatch(test: {'/payload/status': 'active'}),
          equals([
            {'op': 'test', 'path': '/payload/status', 'value': 'active'}
          ]));
    });

    test('passes paths through verbatim — no . to / translation, no / added',
        () {
      expect(
          buildJsonPatch(
            add: {'/payload/user.name': 'Alice'},
            replace: {'/payload/config.ttlSec': 60},
            remove: ['/payload/a.b.c'],
            move: [
              JsonPointerPair(
                  from: '/payload/legacy.name', path: '/payload/display.name')
            ],
            copy: [
              JsonPointerPair(
                  from: '/payload/display.name', path: '/payload/previous.name')
            ],
            test: {'payload.status': 'active'},
          ),
          equals([
            {'op': 'add', 'path': '/payload/user.name', 'value': 'Alice'},
            {'op': 'replace', 'path': '/payload/config.ttlSec', 'value': 60},
            {'op': 'remove', 'path': '/payload/a.b.c'},
            {
              'op': 'move',
              'from': '/payload/legacy.name',
              'path': '/payload/display.name'
            },
            {
              'op': 'copy',
              'from': '/payload/display.name',
              'path': '/payload/previous.name'
            },
            {'op': 'test', 'path': 'payload.status', 'value': 'active'},
          ]));
    });

    test('keeps escaped pointer tokens as they are', () {
      expect(
          buildJsonPatch(remove: ['/payload/a~0b', '/payload/x~1y']),
          equals([
            {'op': 'remove', 'path': '/payload/a~0b'},
            {'op': 'remove', 'path': '/payload/x~1y'},
          ]));
    });

    test(
        'emits operations in a stable order: add, replace, remove, move, '
        'copy, test', () {
      var ops = buildJsonPatch(
        test: {'/h': 3},
        copy: [JsonPointerPair(from: '/f', path: '/g')],
        move: [JsonPointerPair(from: '/d', path: '/e')],
        remove: ['/c'],
        replace: {'/b': 2},
        add: {'/a': 1},
      );

      expect(ops.map((o) => o['op']),
          equals(['add', 'replace', 'remove', 'move', 'copy', 'test']));
    });

    test('keeps the insertion order of several keys in one group', () {
      var ops = buildJsonPatch(replace: {'/z': 1, '/a': 2, '/m': 3});

      expect(ops.map((o) => o['path']), equals(['/z', '/a', '/m']));
    });

    test('returns an empty list when nothing is provided', () {
      expect(buildJsonPatch(), isEmpty);
      expect(
          buildJsonPatch(
              add: {}, replace: {}, remove: [], move: [], copy: [], test: {}),
          isEmpty);
    });

    test('remove, move and copy operations carry no value key', () {
      var ops = buildJsonPatch(
          remove: ['/payload/city'],
          move: [JsonPointerPair(from: '/a', path: '/b')],
          copy: [JsonPointerPair(from: '/c', path: '/d')]);

      expect(ops.every((o) => !o.containsKey('value')), isTrue);
      expect(ops.first.containsKey('from'), isFalse);
    });

    test('keeps null, nested map and list values as they are', () {
      var ops = buildJsonPatch(add: {
        '/a': null,
        '/b': {
          'c': [1, 2]
        },
        '/d': [
          {'e': true}
        ],
      });

      expect(ops.map((o) => o['value']), [
        null,
        {
          'c': [1, 2]
        },
        [
          {'e': true}
        ],
      ]);
      expect(ops.first.containsKey('value'), isTrue);
    });
  });
}
