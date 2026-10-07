import 'dart:async';
import 'dart:convert';

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../net/fake_net.dart';

final _keyset =
    Keyset(subscribeKey: 'demo', publishKey: 'demo', userId: UserId('test'));

const _dataSyncEntityCreate = r'''
{"a":"4","f":0,"e":5,"p":{"t":"17905749563923636","r":21},"k":"demo","c":"u1",
 "d":{"version":"1.0","metadata":{"event":"create","source":"data-sync","type":"entity","className":"DartCustomer","classLevel":"SubKey","classVersion":1},
      "data":{"id":"u1","createdAt":"2026-09-28T05:55:55.583771Z","payload":{"customerId":"u1"}}},
 "b":"u1"}
''';

Map<String, dynamic> _onChannel(String channel) => {
      ...json.decode(_dataSyncEntityCreate) as Map<String, dynamic>,
      'c': channel,
      'b': channel,
    };

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = PubNub(networking: FakeNetworkingModule(), defaultKeyset: _keyset);
  });

  tearDown(() async {
    await pubnub.unsubscribeAll();
  });

  Subscription open(String kind, String id,
      {String? projection,
      Timetoken? timetoken,
      Keyset? keyset,
      String? using}) {
    switch (kind) {
      case 'user':
        return pubnub
            .dataSyncUser(id, keyset: keyset, using: using)
            .subscription(projection: projection, timetoken: timetoken);
      case 'channel':
        return pubnub
            .dataSyncChannel(id, keyset: keyset, using: using)
            .subscription(projection: projection, timetoken: timetoken);
      case 'entity':
        return pubnub
            .dataSyncEntity(id, keyset: keyset, using: using)
            .subscription(projection: projection, timetoken: timetoken);
    }
    throw ArgumentError.value(kind, 'kind');
  }

  group('DataSync entity subscription', () {
    test('returns the matching type and stores the id verbatim', () {
      expect(pubnub.dataSyncUser('  u1 '), isA<DataSyncUser>());
      expect(pubnub.dataSyncChannel('  u1 '), isA<DataSyncChannel>());
      expect(pubnub.dataSyncEntity('customer.*'), isA<DataSyncEntity>());

      for (var id in ['  u1 ', 'customer.*']) {
        expect(pubnub.dataSyncUser(id).id, equals(id));
        expect(pubnub.dataSyncChannel(id).id, equals(id));
        expect(pubnub.dataSyncEntity(id).id, equals(id));
      }

      expect(identical(pubnub.dataSyncUser('u1'), pubnub.dataSyncUser('u1')),
          isFalse);
    });

    test('subscription() is inactive and uses the base channel', () {
      for (var kind in ['user', 'channel', 'entity']) {
        var subscription = open(kind, 'u1');

        expect(subscription.isPaused, isTrue, reason: kind);
        expect(subscription.channels, equals({'u1'}), reason: kind);
        expect(subscription.projection, isNull, reason: kind);
      }
    });

    test('prefixes the channel with a trimmed projection', () {
      for (var kind in ['user', 'channel', 'entity']) {
        var subscription = open(kind, 'u1', projection: ' admin ');

        expect(subscription.channels, equals({'__admin__u1'}), reason: kind);
        expect(subscription.projection, equals('admin'), reason: kind);
      }
    });

    test('preserves the case of the projection name', () {
      var subscription = open('user', 'u1', projection: 'Admin');

      expect(subscription.channels, equals({'__Admin__u1'}));
      expect(subscription.projection, equals('Admin'));
    });

    test('treats base projection aliases as the object channel', () {
      for (var projection in ['', 'default', '__DEFAULT__']) {
        var subscription = open('channel', 'u1', projection: projection);

        expect(subscription.channels, equals({'u1'}), reason: projection);
        expect(subscription.projection, isNull, reason: projection);
      }
    });

    test('prefixes an id that already carries a projection', () {
      var subscription = open('entity', '__admin__u1', projection: 'admin');

      expect(subscription.channels, equals({'__admin____admin__u1'}));
      expect(subscription.projection, equals('admin'));
    });

    test('rejects an empty id', () {
      expect(() => pubnub.dataSyncUser(''), throwsA(isA<InvariantException>()));
      expect(
          () => pubnub.dataSyncChannel(''), throwsA(isA<InvariantException>()));
      expect(
          () => pubnub.dataSyncEntity(''), throwsA(isA<InvariantException>()));
    });

    test('uses the keyset passed in or named with using', () {
      var other = Keyset(
          subscribeKey: 'other-sub',
          publishKey: 'other-pub',
          userId: UserId('other'));
      pubnub.keysets.add('named', other);

      for (var kind in ['user', 'channel', 'entity']) {
        expect(open(kind, 'u1', keyset: other).keyset, same(other),
            reason: kind);
        expect(open(kind, 'u1', using: 'named').keyset, same(other),
            reason: kind);
      }
    });

    test('accepts a timetoken without changing the channel', () {
      var subscription =
          open('user', 'u1', timetoken: Timetoken(BigInt.from(5)));

      expect(subscription.channels, equals({'u1'}));
      expect(subscription.projection, isNull);
    });

    test('subscribes to the projection channel', () async {
      when(
        method: 'GET',
        path: 'v2/subscribe/demo/__admin__u1/0?tt=0&uuid=test',
      ).then(
          status: 200, body: '{"t":{"t":"17905741222336765","r":41},"m":[]}');
      when(
        method: 'GET',
        path:
            'v2/subscribe/demo/__admin__u1/0?tt=17905741222336765&tr=41&uuid=test',
      ).then(
          status: 200,
          body: json.encode({
            't': {'t': '17905741900000001', 'r': 41},
            'm': [_onChannel('u1'), _onChannel('__admin__u1')]
          }));

      var subscription =
          pubnub.dataSyncEntity('u1').subscription(projection: 'admin');

      var dataSync = <DataSyncEvent>[];
      var received = Completer<void>();
      subscription.dataSync.listen((event) {
        dataSync.add(event);
        if (!received.isCompleted) received.complete();
      }, onError: (_) {});

      subscription.subscribe();

      await received.future.timeout(Duration(seconds: 5));
      await Future<void>.delayed(Duration(milliseconds: 50));

      expect(dataSync.map((event) => event.channel), equals(['__admin__u1']));
      expect(dataSync.single.id, equals('u1'));

      await subscription.cancel();
    });
  });
}
