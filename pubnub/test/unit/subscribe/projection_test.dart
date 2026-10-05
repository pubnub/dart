import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/subscribe/projection.dart';

import '../net/fake_net.dart';

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
  group('normalizeProjection', () {
    test('maps the base projection aliases to null', () {
      for (var projection in [
        null,
        '',
        '   ',
        'default',
        'DEFAULT',
        '__default__',
        '__DEFAULT__',
        ' default '
      ]) {
        expect(normalizeProjection(projection), isNull,
            reason: 'projection ${json.encode(projection)}');
      }
    });

    test('trims the name and preserves its case', () {
      expect(normalizeProjection(' admin '), equals('admin'));
      expect(normalizeProjection('Admin'), equals('Admin'));
    });
  });

  group('projectionChannel', () {
    test('uses the id as is for the base projection', () {
      expect(projectionChannel('u1', null), equals('u1'));
    });

    test('prefixes the id with the projection', () {
      expect(projectionChannel('u1', 'admin'), equals('__admin__u1'));
    });

    test('keeps wildcards working', () {
      expect(projectionChannel('customer.*', 'admin'),
          equals('__admin__customer.*'));
    });

    test('uses the id verbatim, even when it is already prefixed', () {
      expect(projectionChannel('__admin__u1', 'admin'),
          equals('__admin____admin__u1'));
    });
  });

  group('Subscription withProjection', () {
    late PubNub pubnub;

    setUp(() {
      pubnub =
          PubNub(networking: FakeNetworkingModule(), defaultKeyset: _keyset);
    });

    test('prefixes channels but not channel groups', () {
      var subscription = pubnub.subscription(
          channels: {'u1', 'u2'},
          channelGroups: {'g'},
          withProjection: 'admin');

      expect(subscription.channels, equals({'__admin__u1', '__admin__u2'}));
      expect(subscription.channelGroups, equals({'g'}));
      expect(subscription.projection, equals('admin'));
    });

    test('normalizes the projection name', () {
      var subscription =
          pubnub.subscription(channels: {'u1'}, withProjection: '  admin ');

      expect(subscription.channels, equals({'__admin__u1'}));
      expect(subscription.projection, equals('admin'));
    });

    test('subscribes the channels as they are for the base projection', () {
      var subscription =
          pubnub.subscription(channels: {'u1'}, withProjection: 'default');

      expect(subscription.channels, equals({'u1'}));
      expect(subscription.projection, isNull);
    });

    test('has no projection by default', () {
      var subscription = pubnub.subscription(channels: {'u1'});

      expect(subscription.channels, equals({'u1'}));
      expect(subscription.projection, isNull);
    });

    test('derives presence channels from the projection channels', () {
      var subscription = pubnub.subscription(
          channels: {'u1'}, withPresence: true, withProjection: 'admin');

      expect(subscription.presenceChannels, equals({'__admin__u1-pnpres'}));
    });

    test('subscribes to the projection channel and emits only its events',
        () async {
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
          pubnub.subscription(channels: {'u1'}, withProjection: 'admin');

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
