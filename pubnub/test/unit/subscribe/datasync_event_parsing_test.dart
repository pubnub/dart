import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';

import '../net/fake_net.dart';

Map<String, dynamic> _wire(
        {required String t,
        required String c,
        String? b,
        required Map<String, dynamic> metadata,
        required Map<String, dynamic> data}) =>
    {
      'a': '5',
      'f': 0,
      'e': 5,
      'p': {'t': t, 'r': 21},
      'c': c,
      if (b != null) 'b': b,
      'd': {'version': '1.0', 'metadata': metadata, 'data': data},
    };

Map<String, dynamic> _metadata(String event, String type, String className,
        {String? classLevel, dynamic classVersion = 1}) =>
    {
      'event': event,
      'source': 'data-sync',
      'type': type,
      'className': className,
      if (classLevel != null) 'classLevel': classLevel,
      'classVersion': classVersion,
    };

final _userData = {
  'id': 'u.cl522260',
  'updatedAt': '2026-08-13T03:42:05.796378Z',
  'createdAt': '2026-08-13T03:42:05.796378Z',
  'eTag': '3w5e11248zuj8',
  'expiresAt': '2026-09-13T00:00:00Z',
  'status': 'st',
  'payload': {'name': 'N'},
};

final _typedUserCreate = _wire(
    t: '17865925262384341',
    c: 'u.cl522260',
    b: 'u.*',
    metadata: _metadata('create', 'user', 'User', classLevel: 'Global'),
    data: _userData);

final _typedChannelUpdate = _wire(
    t: '17865927171226331',
    c: 'chan-829465908',
    metadata: _metadata('update', 'channel', 'Channel', classLevel: 'Global'),
    data: {
      'id': 'chan-829465908',
      'updatedAt': '2026-08-13T03:45:06.930595Z',
      'createdAt': '2026-08-13T03:45:02.278248Z',
      'eTag': '3w5e112493qh2',
      'expiresAt': '2026-09-13T00:00:00Z',
      'status': 'updated',
      'payload': {
        'kind': 'public',
        'name': 'engineering',
        'description': 'engineering',
        'memberCount': 5
      },
    });

final _typedMembershipCreate = _wire(
    t: '17865927498612345',
    c: 'c.mem914058452',
    b: 'c.*',
    metadata:
        _metadata('create', 'membership', 'Membership', classLevel: 'Global'),
    data: {
      'id': 'm.mem914058452',
      'updatedAt': '2026-08-13T03:45:57.918497Z',
      'createdAt': '2026-08-13T03:45:57.918497Z',
      'eTag': '3w5e112494tzu',
      'channelId': 'c.mem914058452',
      'userId': 'u.mem914058452',
      'expiresAt': '2026-09-13T00:00:00Z',
      'status': 'active',
      'payload': {'role': 'member', 'joinedAt': '2026-07-06T10:00:00.000Z'},
    });

final _customEntityCreate = _wire(
    t: '17865926660201074',
    c: 'animal.exp661967',
    b: 'animal.*',
    metadata: _metadata('create', 'entity', 'Lion', classLevel: 'SubKey'),
    data: {
      'id': 'animal.exp661967',
      'updatedAt': '2026-08-13T03:44:25.402304Z',
      'createdAt': '2026-08-13T03:44:25.402304Z',
      'eTag': '3w5e112492uf2',
      'expiresAt': '2027-08-14T00:00:00Z',
      'status': 'some-default-status',
      'payload': {'galaxy': 'MilkyWay', 'planet': 'Earth', 'country': null},
    });

final _customRelationshipCreate = _wire(
    t: '17865927885900138',
    c: 'cust-70b1d0f54f',
    b: 'cust-70b1d0f54f',
    metadata: _metadata('create', 'relationship', 'REQUESTED_BY',
        classLevel: 'SubKey'),
    data: {
      'id': 'rel-c129c5a237',
      'updatedAt': '2026-08-13T03:46:14.806779Z',
      'createdAt': '2026-08-13T03:46:14.806779Z',
      'eTag': '3w5e11249571e',
      'entityAId': 'cust-70b1d0f54f',
      'entityBId': 'lq-871f0a90f3',
      'expiresAt': '2026-08-15T00:00:00Z',
      'status': 'active',
      'payload': {'linkedAt': '2026-07-06T10:00:00.000Z'},
    });

final _typedMembershipDelete = _wire(
    t: '17865927752415830',
    c: 'c.mem914058452',
    b: 'c.*',
    metadata:
        _metadata('delete', 'membership', 'Membership', classLevel: 'Global'),
    data: {'id': 'm.mem914058452', 'deletedAt': '2026-08-13T03:46:14.418911Z'});

final _keyset =
    Keyset(subscribeKey: 'demo', publishKey: 'demo', userId: UserId('test'));

SubscriptionEvent? _event(Map<String, dynamic> wire,
        {Map<String, dynamic>? metadata, Map<String, dynamic>? data}) =>
    SubscriptionEvent.fromEnvelope(
        Envelope.fromJson(json.decode(json.encode({
          ...wire,
          if (metadata != null || data != null)
            'd': {
              ...wire['d'] as Map<String, dynamic>,
              if (metadata != null) 'metadata': metadata,
              if (data != null) 'data': data,
            },
        }))),
        _keyset);

DataSyncEvent _dataSync(Map<String, dynamic> wire,
    {Map<String, dynamic>? metadata, Map<String, dynamic>? data}) {
  var event = _event(wire, metadata: metadata, data: data);
  expect(event, isA<DataSyncEvent>());
  return event as DataSyncEvent;
}

void _expectNoDuplicatedClassFields(Map<String, dynamic> data) {
  for (var key in [
    'entityClass',
    'entityClassVersion',
    'relationshipClass',
    'relationshipClassVersion'
  ]) {
    expect(data.containsKey(key), isFalse, reason: '$key must not be in data');
  }
}

void main() {
  group('DataSync event parsing built-in (Global) classes', () {
    test('parses a typed User create', () {
      var event = _dataSync(_typedUserCreate);

      expect(event.version, equals('1.0'));
      expect(event.source, equals('data-sync'));
      expect(event.event, equals(DataSyncEventType.create));
      expect(event.objectType, equals(DataSyncObjectType.user));
      expect(event.className, equals('User'));
      expect(event.classLevel, equals('Global'));
      expect(event.classVersion, equals(1));
      expect(event.channel, equals('u.cl522260'));
      expect(event.subscription, equals('u.*'));
      expect(event.timetoken,
          equals(Timetoken(BigInt.parse('17865925262384341'))));
    });

    test('passes the User body through verbatim with typed getters', () {
      var event = _dataSync(_typedUserCreate);

      expect(event.data, equals(_userData));
      expect(event.id, equals('u.cl522260'));
      expect(event.status, equals('st'));
      expect(event.payload, equals({'name': 'N'}));
      expect(event.eTag, equals('3w5e11248zuj8'));
      expect(event.createdAt, equals('2026-08-13T03:42:05.796378Z'));
      expect(event.updatedAt, equals('2026-08-13T03:42:05.796378Z'));
      expect(event.expiresAt, equals('2026-09-13T00:00:00Z'));
      expect(event.deletedAt, isNull);
      _expectNoDuplicatedClassFields(event.data);
    });

    test('parses a typed Channel update without a subscription pattern', () {
      var event = _dataSync(_typedChannelUpdate);

      expect(event.event, equals(DataSyncEventType.update));
      expect(event.objectType, equals(DataSyncObjectType.channel));
      expect(event.className, equals('Channel'));
      expect(event.classLevel, equals('Global'));
      expect(event.subscription, isNull);
      expect(event.payload!['memberCount'], equals(5));
      _expectNoDuplicatedClassFields(event.data);
    });

    test('parses a typed Membership create, keeping channelId / userId', () {
      var event = _dataSync(_typedMembershipCreate);

      expect(event.objectType, equals(DataSyncObjectType.membership));
      expect(event.className, equals('Membership'));
      expect(event.channelId, equals('c.mem914058452'));
      expect(event.userId, equals('u.mem914058452'));
      expect(event.entityAId, isNull);
      expect(event.entityBId, isNull);
      _expectNoDuplicatedClassFields(event.data);
    });
  });

  group('DataSync event parsing developer-defined (SubKey) classes', () {
    test('parses a custom entity class, keeping null payload values', () {
      var event = _dataSync(_customEntityCreate);

      expect(event.objectType, equals(DataSyncObjectType.entity));
      expect(event.className, equals('Lion'));
      expect(event.classLevel, equals('SubKey'));
      expect(event.payload!.containsKey('country'), isTrue);
      expect(event.payload!['country'], isNull);
      _expectNoDuplicatedClassFields(event.data);
    });

    test('parses a custom relationship class', () {
      var event = _dataSync(_customRelationshipCreate);

      expect(event.objectType, equals(DataSyncObjectType.relationship));
      expect(event.className, equals('REQUESTED_BY'));
      expect(event.classLevel, equals('SubKey'));
      expect(event.entityAId, equals('cust-70b1d0f54f'));
      expect(event.entityBId, equals('lq-871f0a90f3'));
      expect(event.channelId, isNull);
      _expectNoDuplicatedClassFields(event.data);
    });

    test('does not mistake a developer class named User for the built-in', () {
      var event = _dataSync(_customEntityCreate,
          metadata: _metadata('create', 'entity', 'User',
              classLevel: 'SubKey', classVersion: 2),
          data: {'id': 'animal.exp661967'});

      expect(event.objectType, equals(DataSyncObjectType.entity));
      expect(event.className, equals('User'));
      expect(event.classLevel, equals('SubKey'));
      expect(event.classVersion, equals(2));
    });
  });

  group('DataSync event parsing delete events', () {
    test('a delete body carries only id and deletedAt', () {
      var event = _dataSync(_typedMembershipDelete);

      expect(event.event, equals(DataSyncEventType.delete));
      expect(event.objectType, equals(DataSyncObjectType.membership));
      expect(
          event.data,
          equals({
            'id': 'm.mem914058452',
            'deletedAt': '2026-08-13T03:46:14.418911Z'
          }));
      expect(event.deletedAt, equals('2026-08-13T03:46:14.418911Z'));
      expect(event.payload, isNull);
      expect(event.status, isNull);
      expect(event.eTag, isNull);
    });

    test('an unknown event name maps to unknown', () {
      var event = _dataSync(_typedUserCreate,
          metadata: _metadata('archive', 'user', 'User', classLevel: 'Global'));

      expect(event.event, equals(DataSyncEventType.unknown));
    });
  });

  group('DataSync event parsing service compatibility', () {
    test('parses an event without classLevel', () {
      var event = _dataSync(_typedUserCreate,
          metadata: _metadata('create', 'user', 'User'),
          data: {'id': 'u.cl522260'});

      expect(event.classLevel, isNull);
      expect(event.className, equals('User'));
    });

    // Regression for B-E1: a payload not marked as DataSync is still parsed as DataSync
    // instead of falling back to a message event.
    test('falls back to a message event when source is not data-sync', () {
      var event = _event(_typedUserCreate,
          metadata: {'event': 'create', 'source': 'objects', 'type': 'entity'},
          data: {'id': 'x'});

      expect(event, isA<MessageEvent>());
    });

    // Regression for B-E1: an `e: 5` payload without metadata is dropped silently.
    test('falls back to a message event when metadata is missing', () {
      var event = SubscriptionEvent.fromEnvelope(
          Envelope.fromJson(json.decode(json.encode({
            ..._typedUserCreate,
            'd': {'text': 'hello'}
          }))),
          _keyset);

      expect(event, isA<MessageEvent>());
    });

    // Regression for B-E2: a non-numeric classVersion drops the whole event.
    test('keeps the event with a null classVersion when it is not numeric', () {
      var event = _event(_typedUserCreate,
          metadata: _metadata('create', 'user', 'User',
              classLevel: 'Global', classVersion: 'not-a-number'),
          data: {'id': 'u.cl522260'});

      expect(event, isA<DataSyncEvent>());
      expect((event as DataSyncEvent).classVersion, isNull);
    });

    // Regression for B-E2: a numeric string classVersion drops the whole event.
    test('parses a numeric string classVersion', () {
      var event = _event(_typedUserCreate,
          metadata: _metadata('create', 'user', 'User',
              classLevel: 'Global', classVersion: '3'),
          data: {'id': 'u.cl522260'});

      expect(event, isA<DataSyncEvent>());
      expect((event as DataSyncEvent).classVersion, equals(3));
    });

    // Regression for B-E3: objectType is not derived from the reserved class identity
    // when the wire type is the generic kind.
    test('derives objectType user from a Global User entity', () {
      var event = _dataSync(_typedUserCreate,
          metadata: _metadata('create', 'entity', 'User', classLevel: 'Global'),
          data: {'id': 'u.cl522260'});

      expect(event.objectType, equals(DataSyncObjectType.user));
    });

    // Regression for B-E3
    test('derives objectType membership from a Global Membership relationship',
        () {
      var event = _dataSync(_typedMembershipCreate,
          metadata: _metadata('create', 'relationship', 'Membership',
              classLevel: 'Global'),
          data: {
            'id': 'm.mem914058452',
            'entityAId': 'c.mem914058452',
            'entityBId': 'u.mem914058452'
          });

      expect(event.objectType, equals(DataSyncObjectType.membership));
      expect(event.entityAId, equals('c.mem914058452'));
    });

    // Regression for B-E4: the retired positional composite className is not normalized.
    test('tolerates the retired positional composite className', () {
      var user = _dataSync(_typedUserCreate,
          metadata: _metadata('create', 'entity', 'User::'),
          data: {'id': 'u.cl522260'});
      var lion = _dataSync(_customEntityCreate,
          metadata: _metadata('create', 'entity', '::Lion'),
          data: {'id': 'animal.exp661967'});

      expect(user.className, equals('User'));
      expect(lion.className, equals('Lion'));
    });
  });

  group('DataSync event parsing fallback and discard rules', () {
    test('the message fallback keeps the original payload', () {
      var event = _event(_typedUserCreate,
          metadata: {'event': 'create', 'source': 'objects', 'type': 'entity'},
          data: {'id': 'x'}) as MessageEvent;

      expect((event.message as Map)['data'], equals({'id': 'x'}));
    });

    test('a DataSync payload without event or type is a message', () {
      expect(
          _event(_typedUserCreate,
              metadata: {'source': 'data-sync', 'type': 'user'}),
          isA<MessageEvent>());
      expect(
          _event(_typedUserCreate,
              metadata: {'source': 'data-sync', 'event': 'create'}),
          isA<MessageEvent>());
    });

    test('a DataSync payload of an unknown object type is discarded', () {
      expect(
          _event(_typedUserCreate,
              metadata: _metadata('create', 'space', 'Space')),
          isNull);
    });

    test('a DataSync payload without data or id is discarded', () {
      expect(
          SubscriptionEvent.fromEnvelope(
              Envelope.fromJson(json.decode(json.encode({
                ..._typedUserCreate,
                'd': {
                  'version': '1.0',
                  'metadata': _metadata('create', 'user', 'User')
                }
              }))),
              _keyset),
          isNull);
      expect(_event(_typedUserCreate, data: {'status': 'x'}), isNull);
    });

    test('a numeric classVersion of type double is truncated', () {
      var event = _dataSync(_typedUserCreate,
          metadata: _metadata('create', 'user', 'User', classVersion: 2.0));

      expect(event.classVersion, equals(2));
    });
  });

  group('DataSync event parsing subscription stream', () {
    test('delivers DataSync events on dataSync only, with a crypto module',
        () async {
      var pubnub = PubNub(
          networking: FakeNetworkingModule(),
          defaultKeyset: _keyset,
          crypto:
              CryptoModule.aesCbcCryptoModule(CipherKey.fromUtf8('enigma')));

      when(method: 'GET', path: 'v2/subscribe/demo/c.*/0?tt=0&uuid=test').then(
          status: 200, body: '{"t":{"t":"17905741222336765","r":41},"m":[]}');
      when(
        method: 'GET',
        path: 'v2/subscribe/demo/c.*/0?tt=17905741222336765&tr=41&uuid=test',
      ).then(
          status: 200,
          body: json.encode({
            't': {'t': '17905741900000001', 'r': 41},
            'm': [_typedMembershipCreate, _typedMembershipDelete]
          }));

      var subscription = pubnub.subscription(channels: {'c.*'});
      var messages = <Envelope>[];
      var dataSync = <DataSyncEvent>[];
      var received = Completer<void>();
      void ignore(Object _) {}
      subscription.messages.listen(messages.add, onError: ignore);
      subscription.dataSync.listen((event) {
        dataSync.add(event);
        if (dataSync.length == 2) received.complete();
      }, onError: ignore);

      subscription.subscribe();
      await received.future.timeout(Duration(seconds: 5));
      await subscription.cancel();

      expect(dataSync.map((e) => e.event),
          [DataSyncEventType.create, DataSyncEventType.delete]);
      expect(dataSync.first.subscription, equals('c.*'));
      expect(messages, isEmpty);
    });
  });
}
