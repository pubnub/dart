import 'dart:convert';

import 'package:test/test.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/pubnub.dart' show UserId, InvariantException;
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/pam/resource.dart';
import 'package:pubnub/src/dx/pam/token.dart';

import '../net/fake_net.dart';

/// Networking module that records every request and answers it with a
/// successful grant response.
class _RecordingNetworkingModule extends FakeNetworkingModule {
  final List<Request> requests = [];

  @override
  Future<IRequestHandler> handler() async => _RecordingHandler(this);
}

class _RecordingHandler extends IRequestHandler {
  final _RecordingNetworkingModule module;

  _RecordingHandler(this.module);

  @override
  Future<IResponse> response(Request request) async {
    module.requests.add(request);
    return MockResponse(
        statusCode: 200,
        body: json.encode({
          'status': 200,
          'data': {'message': 'Success', 'token': _token({})}
        }));
  }

  @override
  void cancel([dynamic reason]) {}

  @override
  bool get isCancelled => false;
}

// Minimal CBOR encoder (RFC 8949) covering the types used by PAM tokens.
List<int> _cborHead(int major, int length) {
  if (length < 24) return [(major << 5) | length];
  if (length < 256) return [(major << 5) | 24, length];
  if (length < 65536) {
    return [(major << 5) | 25, length >> 8, length & 0xff];
  }
  return [
    (major << 5) | 26,
    (length >> 24) & 0xff,
    (length >> 16) & 0xff,
    (length >> 8) & 0xff,
    length & 0xff
  ];
}

List<int> _cbor(dynamic value) {
  if (value is int) return _cborHead(0, value);
  if (value is String) {
    var bytes = utf8.encode(value);
    return [..._cborHead(3, bytes.length), ...bytes];
  }
  if (value is List<int>) return [..._cborHead(2, value.length), ...value];
  if (value is Map) {
    return [
      ..._cborHead(5, value.length),
      // Like the server, encode keys as byte strings.
      for (var entry in value.entries) ...[
        ..._cbor(utf8.encode(entry.key as String)),
        ..._cbor(entry.value)
      ]
    ];
  }
  throw ArgumentError('unsupported CBOR value $value');
}

/// Builds a v2 PAM token carrying [fields] on top of the mandatory ones.
String _token(Map<String, dynamic> fields) => base64Url
    .encode(_cbor({
      'v': 2,
      't': 1700000000,
      'ttl': 60,
      'res': <String, dynamic>{},
      'pat': <String, dynamic>{},
      'meta': <String, dynamic>{},
      'sig': [1, 2, 3, 4],
      ...fields,
    }))
    .replaceAll('=', '');

void main() {
  late PubNub pubnub;
  late _RecordingNetworkingModule networking;

  setUp(() {
    networking = _RecordingNetworkingModule();
    pubnub = PubNub(
        defaultKeyset: Keyset(
            subscribeKey: 'test-sub-key',
            publishKey: 'test-pub-key',
            secretKey: 'test-secret-key',
            userId: UserId('test-uuid')),
        networking: networking);
  });

  Map<String, dynamic> sentPermissions() {
    var body = json.decode(networking.requests.single.body as String);
    return body['permissions'] as Map<String, dynamic>;
  }

  group('PAM [categories] addCategory validation', () {
    test('accepts channel and uuid', () {
      var request = pubnub.requestToken(ttl: 60);

      expect(() => request.addCategory(ResourceType.channel), returnsNormally);
      expect(() => request.addCategory(ResourceType.uuid), returnsNormally);
    });

    test('rejects every type that does not support categories', () {
      var unsupported =
          ResourceType.values.where((type) => !type.supportsCategory);

      expect(
          unsupported,
          unorderedEquals([
            ResourceType.channelGroup,
            ResourceType.user,
            ResourceType.space,
            ResourceType.entity,
            ResourceType.relationship,
            ResourceType.membership,
          ]));

      for (var type in unsupported) {
        var request = pubnub.requestToken(ttl: 60);

        expect(
            () => request.addCategory(type), throwsA(isA<InvariantException>()),
            reason: '$type');
      }
    });

    test('categoryScope maps only channel and uuid', () {
      expect(ResourceType.channel.categoryScope, equals('channels'));
      expect(ResourceType.uuid.categoryScope, equals('uuids'));
      // `space` shares the `channels` grant scope but has no category.
      expect(ResourceType.space.value, equals('channels'));
      expect(ResourceType.space.categoryScope, isNull);

      for (var type in ResourceType.values.where((type) =>
          type != ResourceType.channel && type != ResourceType.uuid)) {
        expect(type.categoryScope, isNull, reason: '$type');
      }
    });
  });

  group('PAM [categories] grantToken request body', () {
    test('sends a grant carrying only a category', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..addCategory(ResourceType.channel);

      await pubnub.grantToken(request);

      var permissions = sentPermissions();
      expect(permissions['categories'], equals({'channels': 32}));
      expect(permissions['resources'],
          equals({'channels': {}, 'groups': {}, 'uuids': {}, 'users': {}}));
      expect(permissions['patterns'],
          equals({'channels': {}, 'groups': {}, 'uuids': {}, 'users': {}}));
    });

    test('encodes both categories', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..addCategory(ResourceType.channel)
        ..addCategory(ResourceType.uuid);

      await pubnub.grantToken(request);

      expect(sentPermissions()['categories'],
          equals({'channels': 32, 'uuids': 32}));
    });

    test('adding the same category twice is idempotent', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..addCategory(ResourceType.channel)
        ..addCategory(ResourceType.channel);

      await pubnub.grantToken(request);

      expect(sentPermissions()['categories'], equals({'channels': 32}));
    });

    test('encodes categories independently of resources and patterns',
        () async {
      var request = pubnub.requestToken(ttl: 60)
        ..add(ResourceType.channel, name: 'ch-1', get: true)
        ..add(ResourceType.uuid, pattern: 'u-.*', get: true)
        ..addCategory(ResourceType.uuid);

      await pubnub.grantToken(request);

      var permissions = sentPermissions();
      expect(permissions['resources']['channels'], equals({'ch-1': 32}));
      expect(permissions['resources']['uuids'], isEmpty);
      expect(permissions['patterns']['uuids'], equals({'u-.*': 32}));
      expect(permissions['patterns']['channels'], isEmpty);
      expect(permissions['categories'], equals({'uuids': 32}));
    });

    test('omits categories when none were added', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..add(ResourceType.channel, name: 'ch-1', get: true);

      await pubnub.grantToken(request);

      expect(sentPermissions().containsKey('categories'), isFalse);
    });

    test('keeps meta, authorized uuid and projections alongside categories',
        () async {
      var request = pubnub.requestToken(
          ttl: 60, meta: {'app': 'dart'}, authorizedUUID: 'auth-uuid')
        ..add(ResourceType.entity, name: 'e-1', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            name: 'e-1', projection: 'admin')
        ..addCategory(ResourceType.channel);

      await pubnub.grantToken(request);

      var permissions = sentPermissions();
      expect(permissions['categories'], equals({'channels': 32}));
      expect(permissions['uuid'], equals('auth-uuid'));
      expect(
          permissions['meta'],
          equals({
            'app': 'dart',
            'pn-projections': {
              'res': {'datasync:entities:e-1': 'admin'}
            }
          }));
    });

    test('rejects a grant without resources or categories', () {
      var request = pubnub.requestToken(ttl: 60);

      expect(pubnub.grantToken(request), throwsA(isA<InvariantException>()));
      expect(networking.requests, isEmpty);
    });

    test('allows projections alongside only categories', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..addDataSyncProjection(ResourceType.entity,
            name: 'e-1', projection: 'admin')
        ..addCategory(ResourceType.uuid);

      await pubnub.grantToken(request);

      expect(sentPermissions()['categories'], equals({'uuids': 32}));
    });

    test('sends a categories-only grant signed to the grant endpoint',
        () async {
      var request = pubnub.requestToken(ttl: 60)
        ..addCategory(ResourceType.channel);

      await pubnub.grantToken(request);

      var uri = networking.requests.single.uri!;
      expect(uri.path, endsWith('v3/pam/test-sub-key/grant'));
      expect(uri.queryParameters, contains('signature'));
      expect(uri.queryParameters, contains('timestamp'));
    });
  });

  group('PAM [categories] Token decoding', () {
    test('decodes category-level permissions', () {
      var token = Token(_token({
        'cat': {'chan': 32, 'uuid': 32}
      }));

      expect(
          token.categories
              .map((c) => [c.type, c.name, c.pattern, c.bit, c.get]),
          unorderedEquals([
            [ResourceType.channel, null, null, 32, true],
            [ResourceType.uuid, null, null, 32, true],
          ]));
    });

    test('a token without categories has none', () {
      var token = Token(_token({
        'res': {
          'chan': {'ch-1': 1}
        },
      }));

      expect(token.categories, isEmpty);
      expect(token.resources.single.name, equals('ch-1'));
      expect(token.patterns, isEmpty);
    });

    test('skips unknown categories and malformed entries', () {
      var token = Token(_token({
        'cat': {'grp': 32, 'future': 32, 'chan': 'x', 'uuid': 32}
      }));

      expect(token.categories.map((c) => c.type), [ResourceType.uuid]);
    });

    test('categories do not leak into resources or patterns', () {
      var token = Token(_token({
        'res': {
          'chan': {'ch-1': 1}
        },
        'cat': {'chan': 32},
      }));

      expect(token.resources.single.name, equals('ch-1'));
      expect(token.resources.single.bit, equals(1));
      expect(token.patterns, isEmpty);
      expect(token.categories.single.type, equals(ResourceType.channel));
      expect(token.categories.single.name, isNull);
      expect(token.categories.single.pattern, isNull);
    });
  });
}
