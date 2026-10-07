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

  group('PAM [DataSync] grantToken request body', () {
    test('encodes DataSync resources and patterns under their scopes',
        () async {
      var request = pubnub.requestToken(ttl: 60)
        ..add(ResourceType.entity, name: 'dartcustomer-1', get: true)
        ..add(ResourceType.relationship,
            pattern: 'dartrequestedby-.*', get: true, update: true)
        ..add(ResourceType.membership, name: 'm-1', delete: true)
        ..add(ResourceType.user, name: 'dartuser-1', get: true);

      await pubnub.grantToken(request);

      var permissions = sentPermissions();
      expect(permissions['resources']['datasync:entities'],
          equals({'dartcustomer-1': 32}));
      expect(
          permissions['resources']['datasync:memberships'], equals({'m-1': 8}));
      expect(permissions['resources']['users'], equals({'dartuser-1': 32}));
      expect(permissions['patterns']['datasync:relationships'],
          equals({'dartrequestedby-.*': 96}));
      expect(permissions.containsKey('meta'), isFalse);
    });

    test('encodes projections into meta pn-projections, merged with meta',
        () async {
      var request = pubnub.requestToken(ttl: 60, meta: {'app': 'dart'})
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            name: 'dartcustomer-1', projection: 'admin')
        ..addDataSyncProjection(ResourceType.membership,
            pattern: 'user.*:channel.*', projection: defaultProjection)
        ..addDataSyncProjection(ResourceType.user,
            pattern: 'dartuser-.*', projection: 'admin')
        ..addDataSyncProjection(ResourceType.channel,
            name: 'dartchannel-1', projection: 'admin');

      await pubnub.grantToken(request);

      expect(
          sentPermissions()['meta'],
          equals({
            'app': 'dart',
            'pn-projections': {
              'res': {
                'datasync:entities:dartcustomer-1': 'admin',
                'datasync:channels:dartchannel-1': 'admin',
              },
              'pat': {
                'datasync:memberships:user.*:channel.*': '__default__',
                'datasync:users:dartuser-.*': 'admin',
              },
            }
          }));
    });

    // Regression for B2: the server always rejects a grant that only carries
    // projections ("This grant contains no permissions"), but the SDK sends
    // it anyway. When fixed, flip `grantToken allows a grant carrying only
    // projections` in pam_test.dart as well.
    test('rejects a grant carrying only projections locally', () {
      var request = pubnub.requestToken(ttl: 60)
        ..addDataSyncProjection(ResourceType.entity,
            name: 'dartcustomer-1', projection: 'admin');

      expect(pubnub.grantToken(request), throwsA(isA<InvariantException>()));
    });

    // Regression for B19: an empty name passes `isNotNull` validation.
    test('addDataSyncProjection rejects an empty name', () {
      var request = pubnub.requestToken(ttl: 60);

      expect(
          () => request.addDataSyncProjection(ResourceType.entity,
              name: '', projection: 'admin'),
          throwsA(isA<InvariantException>()));
    });

    test('addDataSyncProjection rejects an empty projection', () {
      var request = pubnub.requestToken(ttl: 60);

      expect(
          () => request.addDataSyncProjection(ResourceType.entity,
              name: 'dartcustomer-1', projection: ''),
          throwsA(isA<InvariantException>()));
    });
  });

  group('PAM [DataSync] Token decoding', () {
    test('decodes DataSync resources and patterns', () {
      var token = Token(_token({
        'res': {
          'datasync:entities': {'dartcustomer-1': 32},
          'datasync:memberships': {'m-1': 8},
          'chan': {'ch-1': 1},
        },
        'pat': {
          'datasync:relationships': {'dartrequestedby-.*': 96},
        },
      }));

      expect(
          token.resources.map((r) => [r.type, r.name, r.bit]),
          unorderedEquals([
            [ResourceType.entity, 'dartcustomer-1', 32],
            [ResourceType.membership, 'm-1', 8],
            [ResourceType.channel, 'ch-1', 1],
          ]));
      expect(token.patterns.single.type, equals(ResourceType.relationship));
      expect(token.patterns.single.pattern, equals('dartrequestedby-.*'));
    });

    test('skips unknown scopes instead of failing', () {
      var token = Token(_token({
        'res': {
          'datasync:future': {'x': 1},
          'datasync:entities': {'e': 32},
        },
      }));

      expect(token.resources.map((r) => r.type), [ResourceType.entity]);
    });

    test('decodes pn-projections, including ids that contain ":"', () {
      var token = Token(_token({
        'meta': {
          'app': 'dart',
          'pn-projections': {
            'res': {
              'datasync:entities:dartcustomer-1': 'admin',
              'datasync:channels:dartchannel-1': '__default__',
            },
            'pat': {
              'datasync:memberships:user.*:channel.*': 'admin',
              'datasync:users:dartuser-.*': 'admin',
            },
          }
        },
      }));

      expect(
          token.projections
              .map((p) => [p.type, p.name, p.pattern, p.projection]),
          unorderedEquals([
            [ResourceType.entity, 'dartcustomer-1', null, 'admin'],
            [ResourceType.channel, 'dartchannel-1', null, '__default__'],
            [ResourceType.membership, null, 'user.*:channel.*', 'admin'],
            [ResourceType.user, null, 'dartuser-.*', 'admin'],
          ]));
      expect(token.meta['app'], equals('dart'));
    });

    test('a token without projections has none', () {
      expect(Token(_token({})).projections, isEmpty);
    });

    test('ignores malformed projection entries', () {
      var token = Token(_token({
        'meta': {
          'pn-projections': {
            'res': {
              'datasync:entities:': 'admin',
              'unknown:scope:x': 'admin',
              'datasync:entities:ok': 'admin',
            },
          }
        },
      }));

      expect(token.projections.map((p) => p.name), ['ok']);
    });
  });
}
