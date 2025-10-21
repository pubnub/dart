import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import '../net/fake_net.dart';

void main() {
  group('DX [batch history]', () {
    late PubNub pubnub;

    setUp(() {
      pubnub = PubNub(
        defaultKeyset:
            Keyset(subscribeKey: 'sub', publishKey: 'pub', userId: UserId('u')),
        networking: FakeNetworkingModule(),
      );
    });

    test('fetchMessages defaults for single channel', () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
        status: 200,
        body:
            '{"status":200,"error":false,"channels":{"ch1":[{"message":42,"timetoken":"1","message_type":0}]}}',
      );

      var r = await pubnub.batch.fetchMessages({'ch1'});

      expect(r.channels['ch1']!.length, equals(1));
      expect(r.channels['ch1']![0].message, equals(42));
      expect(r.channels['ch1']![0].error, isNull);
    });

    test('fetchMessages defaults for multiple channels use max=25', () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1,ch2?max=25&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":[],"ch2":[]}}');

      await pubnub.batch.fetchMessages({'ch1', 'ch2'});
    });

    test(
        'fetchMessages includeMessageActions uses history-with-actions and single channel only',
        () async {
      when(
        method: 'GET',
        path:
            'v3/history-with-actions/sub-key/sub/channel/ch1?max=25&include_message_type=true&include_custom_message_type=false&include_uuid=true&include_meta=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
        status: 200,
        body:
            '{"status":200,"error":false,"channels":{"ch1":[{"message":42,"timetoken":"1","message_type":0,"actions":{"reaction":{"smile":[{"uuid":"u","actionTimetoken":"2"}]}}}]}}',
      );

      var r = await pubnub.batch.fetchMessages({'ch1'},
          includeMessageActions: true, includeMeta: true);
      expect(r.channels['ch1']![0].actions, isA<Map>());
    });

    test(
        'fetchMessages throws when includeMessageActions with multiple channels',
        () async {
      expect(
          () => pubnub.batch
              .fetchMessages({'a', 'b'}, includeMessageActions: true),
          throwsA(isA<InvariantException>()));
    });

    test('fetchMessages respects start end reverse flags', () async {
      var start = Timetoken(BigInt.from(10));
      var end = Timetoken(BigInt.from(20));

      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&reverse=true&start=10&end=20&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":[]}}');

      await pubnub.batch
          .fetchMessages({'ch1'}, reverse: true, start: start, end: end);
    });

    test(
        'fetchMessages toggles include flags messageType customMessageType uuid',
        () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&include_message_type=false&include_custom_message_type=true&include_uuid=false&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":[]}}');

      await pubnub.batch.fetchMessages({'ch1'},
          includeMessageType: false,
          includeCustomMessageType: true,
          includeUUID: false);
    });

    test('fetchMessages maps meta empty string to null', () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
        status: 200,
        body:
            '{"status":200,"error":false,"channels":{"ch1":[{"message":42,"timetoken":"1","message_type":0,"meta":""}]}}',
      );

      var r = await pubnub.batch.fetchMessages({'ch1'});
      expect(r.channels['ch1']![0].meta, isNull);
    });

    test('fetchMessages maps more field to MoreHistory', () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
        status: 200,
        body:
            '{"status":200,"error":false,"channels":{"ch1":[]},"more":{"url":"/v3/history/sub-key/sub/channel/ch1","start":"1","max":100}}',
      );

      var r = await pubnub.batch.fetchMessages({'ch1'});
      expect(r.more, isNotNull);
      expect(r.more!.start, equals('1'));
      expect(r.more!.count, equals(100));
    });

    test('fetchMessages decryption failure retains payload and sets error',
        () async {
      // Create PubNub instance with crypto module to trigger decryption
      final cryptoPubNub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'sub',
          publishKey: 'pub',
          userId: UserId('u'),
        ),
        crypto: CryptoModule.legacyCryptoModule(CipherKey.fromUtf8('testkey')),
        networking: FakeNetworkingModule(),
      );

      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
        status: 200,
        body:
            '{"status":200,"error":false,"channels":{"ch1":[{"message":123,"timetoken":"1","message_type":0}]}}',
      );

      var r = await cryptoPubNub.batch.fetchMessages({'ch1'});
      expect(r.channels['ch1']![0].message, equals(123));
      expect(r.channels['ch1']![0].error, isA<PubNubException>());
    });

    test('fetchMessages uses named keyset', () async {
      pubnub.keysets.add('alt',
          Keyset(subscribeKey: 's2', publishKey: 'p2', userId: UserId('u')));

      when(
        method: 'GET',
        path:
            'v3/history/sub-key/s2/channel/ch1?max=100&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":[]}}');

      await pubnub.batch.fetchMessages({'ch1'}, using: 'alt');
    });

    test('fetchMessages includes auth when authKey set', () async {
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'sub',
          publishKey: 'pub',
          authKey: 'auth',
          userId: UserId('u'),
        ),
        networking: FakeNetworkingModule(),
      );

      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&include_message_type=true&include_custom_message_type=false&include_uuid=true&auth=auth&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":[]}}');

      await pubnub.batch.fetchMessages({'ch1'});
    });

    test('fetchMessages adds signature when secretKey set', () async {
      final currentVersion = PubNub.version;
      final currentCoreVersion = Core.version;
      PubNub.version = '1.0.0';
      Core.version = '1.0.0';
      Time.mock(DateTime.fromMillisecondsSinceEpoch(1700000000000));

      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'sub',
          publishKey: 'pub',
          secretKey: 'sec',
          userId: UserId('u'),
        ),
        networking: FakeNetworkingModule(),
      );

      // Build expected signature like defaultFlow would
      var baseUri = Uri(pathSegments: [
        'v3',
        'history',
        'sub-key',
        'sub',
        'channel',
        'ch1',
      ], queryParameters: {
        'max': '100',
        'include_message_type': 'true',
        'include_custom_message_type': 'false',
        'include_uuid': 'true',
        'uuid': 'u',
      });

      var timestamp = '${Time().now()!.millisecondsSinceEpoch ~/ 1000}';
      var uriWithTs = baseUri.replace(queryParameters: {
        ...baseUri.queryParameters,
        'timestamp': timestamp,
      });
      var signature = computeV2Signature(
        pubnub.keysets.defaultKeyset,
        RequestType.get,
        uriWithTs.pathSegments,
        uriWithTs.queryParameters,
        'null',
      );

      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/channel/ch1?max=100&include_message_type=true&include_custom_message_type=false&include_uuid=true&uuid=u&timestamp=$timestamp&signature=$signature&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":[]}}');

      await pubnub.batch.fetchMessages({'ch1'});

      PubNub.version = currentVersion;
      Core.version = currentCoreVersion;
      Time.unmock();
    });

    test('fetchMessages throws when no keyset available', () async {
      pubnub.keysets.remove('default');
      expect(() => pubnub.batch.fetchMessages({'ch1'}),
          throwsA(isA<KeysetException>()));
    });

    test('countMessages Set<String> variant requires timetoken and builds path',
        () async {
      var tt = Timetoken(BigInt.from(1));

      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/message-counts/ch1,ch2?timetoken=1&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":1,"ch2":2}}');

      var r = await pubnub.batch.countMessages({'ch1', 'ch2'}, timetoken: tt);
      expect(r.channels['ch1'], equals(1));
      expect(r.channels['ch2'], equals(2));
    });

    test(
        'countMessages Map<String, Timetoken> variant builds path and channelsTimetoken CSV',
        () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/sub/message-counts/ch1,ch2?channelsTimetoken=1,2&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":10,"ch2":20}}');

      var r = await pubnub.batch.countMessages({
        'ch1': Timetoken(BigInt.from(1)),
        'ch2': Timetoken(BigInt.from(2)),
      });
      expect(r.channels['ch1'], equals(10));
      expect(r.channels['ch2'], equals(20));
    });

    test('countMessages using named keyset', () async {
      pubnub.keysets.add('alt',
          Keyset(subscribeKey: 's2', publishKey: 'pub', userId: UserId('u')));

      when(
        method: 'GET',
        path:
            'v3/history/sub-key/s2/message-counts/ch1?timetoken=1&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(
          status: 200,
          body: '{"status":200,"error":false,"channels":{"ch1":5}}');

      var r = await pubnub.batch.countMessages({'ch1'},
          using: 'alt', timetoken: Timetoken(BigInt.from(1)));
      expect(r.channels['ch1'], equals(5));
    });

    test('countMessages throws for Set variant without timetoken', () async {
      expect(() => pubnub.batch.countMessages({'ch1'}),
          throwsA(isA<InvariantException>()));
    });

    test('countMessages throws for invalid channels type', () async {
      expect(() => pubnub.batch.countMessages(123),
          throwsA(isA<InvariantException>()));
    });
  });

  group('delete()', () {
    late PubNub pubnub;

    setUp(() {
      pubnub = PubNub(
        defaultKeyset:
            Keyset(subscribeKey: 'sub', publishKey: 'pub', userId: UserId('u')),
        networking: FakeNetworkingModule(),
      );
    });
    test('delete with no from/to parameters', () async {
      var channel = pubnub.channel('test-channel');
      var history = channel.messages();

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/test-channel?uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with from parameter only', () async {
      var channel = pubnub.channel('test-channel');
      var fromTimetoken = Timetoken(BigInt.from(15610547826970050));
      var history = channel.messages(from: fromTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/test-channel?start=15610547826970050&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with to parameter only', () async {
      var channel = pubnub.channel('test-channel');
      var toTimetoken = Timetoken(BigInt.from(15645905639093361));
      var history = channel.messages(to: toTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/test-channel?end=15645905639093361&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with both from and to parameters', () async {
      var channel = pubnub.channel('test-channel');
      var fromTimetoken = Timetoken(BigInt.from(15610547826970050));
      var toTimetoken = Timetoken(BigInt.from(15645905639093361));
      var history = channel.messages(from: fromTimetoken, to: toTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/test-channel?start=15610547826970050&end=15645905639093361&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with different channel name', () async {
      var channel = pubnub.channel('another-channel');
      var fromTimetoken = Timetoken(BigInt.from(12345));
      var toTimetoken = Timetoken(BigInt.from(67890));
      var history = channel.messages(from: fromTimetoken, to: toTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/another-channel?start=12345&end=67890&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with authKey in keyset', () async {
      pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'sub',
          publishKey: 'pub',
          authKey: 'myAuthKey',
          userId: UserId('u'),
        ),
        networking: FakeNetworkingModule(),
      );

      var channel = pubnub.channel('test-channel');
      var fromTimetoken = Timetoken(BigInt.from(1000));
      var toTimetoken = Timetoken(BigInt.from(2000));
      var history = channel.messages(from: fromTimetoken, to: toTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/test-channel?start=1000&end=2000&auth=myAuthKey&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with named keyset', () async {
      pubnub.keysets.add(
          'alt',
          Keyset(
              subscribeKey: 'alt-sub',
              publishKey: 'alt-pub',
              userId: UserId('u')));

      var channel = pubnub.channel('test-channel', using: 'alt');
      var fromTimetoken = Timetoken(BigInt.from(100));
      var toTimetoken = Timetoken(BigInt.from(200));
      var history = channel.messages(from: fromTimetoken, to: toTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/alt-sub/channel/test-channel?start=100&end=200&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with very large timetoken values', () async {
      var channel = pubnub.channel('test-channel');
      var fromTimetoken = Timetoken(BigInt.parse('99999999999999999'));
      var toTimetoken = Timetoken(BigInt.parse('99999999999999999999'));
      var history = channel.messages(from: fromTimetoken, to: toTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/test-channel?start=99999999999999999&end=99999999999999999999&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });

    test('delete with special characters in channel name', () async {
      var channel = pubnub.channel('test-channel-with-special_chars.123');
      var fromTimetoken = Timetoken(BigInt.from(100));
      var history = channel.messages(from: fromTimetoken);

      when(
        method: 'DELETE',
        path:
            'v3/history/sub-key/sub/channel/test-channel-with-special_chars.123?start=100&uuid=u&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: '{"status":200,"error":false,"message":""}');

      await history.delete();
    });
  });
}
