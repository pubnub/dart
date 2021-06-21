import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_endpoints/history.dart';

import '../net/fake_net.dart';
part './fixtures/history.dart';

void main() {
  late PubNub pubnub;
  group('DX [history]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test', publishKey: 'test', uuid: UUID('test')),
          networking: FakeNetworkingModule());
    });

    test('.batch#fetchMessages correctly fetches messages', () async {
      when(
        path:
            'v3/history/sub-key/test/channel/test-1,test-2?max=10&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _batchFetchMessagesSuccessResponse);

      var result =
          await pubnub.batch.fetchMessages({'test-1', 'test-2'}, count: 10);

      expect(result.channels['test-1'], isA<List<BatchHistoryResultEntry>>());
      expect(result.channels['test-1']!.length, equals(1));
      expect(result.channels['test-1']![0].message, equals(42));
      expect(result.channels['test-1']![0].uuid, equals('test-uuid'));
      expect(result.channels['test-2'], isA<List<BatchHistoryResultEntry>>());
      expect(result.channels['test-2']!.length, equals(1));
      expect(result.channels['test-2']![0].message, equals(10));
      expect(result.channels['test-2']![0].uuid, equals('test-uuid'));
    });

    test('.batch#countMessages correctly fetches counts when passed in Set',
        () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/test/message-counts/test-1,test-2?timetoken=100&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _batchCountMessagesSuccessResponse);

      var result = await pubnub.batch.countMessages({'test-1', 'test-2'},
          timetoken: Timetoken(BigInt.from(100)));

      expect(result.channels['test-1'], equals(42));
      expect(result.channels['test-2'], equals(10));
    });

    test('.batch#fetchMessagesWith Message Actions for multiple channels',
        () async {
      when(
        path:
            'v3/history-with-actions/sub-key/test/channel/demo-channel?max=10&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _batchFetchMessagesWithActionsWithMore);

      expect(
          pubnub.batch.fetchMessages({'demo-channel', 'channel_2'},
              includeMessageActions: true, count: 10),
          throwsA(TypeMatcher<PubNubException>()));
    });
    test('.batch#fetchMessages with messageActions', () async {
      when(
        path:
            'v3/history-with-actions/sub-key/test/channel/demo-channel?max=10&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _batchFetchMessagesWithActionSuccessResponse);

      var result = await pubnub.batch.fetchMessages({'demo-channel'},
          includeMessageActions: true, count: 10);

      expect(result.channels['demo-channel'],
          isA<List<BatchHistoryResultEntry>>());
      expect(result.channels['demo-channel']![0].actions,
          isA<Map<String, dynamic>>());
      expect(result.channels['demo-channel']![0].actions!['receipt']['read'],
          isA<List>());
      expect(result.channels['demo-channel']![0].timetoken,
          equals(Timetoken(BigInt.from(15610547826970040))));
    });

    test('.batch#fetchMessages with more messages', () async {
      when(
        path:
            'v3/history-with-actions/sub-key/test/channel/demo-channel?max=10&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _batchFetchMessagesWithActionsWithMore);

      var result = await pubnub.batch.fetchMessages({'demo-channel'},
          includeMessageActions: true, count: 10);

      expect(result.channels['demo-channel'],
          isA<List<BatchHistoryResultEntry>>());
      expect(result.channels['demo-channel']!.length, equals(2));
      expect(result.channels['demo-channel']![1].actions!['reaction'].length,
          equals(2));
      expect(
          result.more!.url,
          equals(
              '/v1/history-with-actions/s/channel/c?start=15610547826970000&max=98'));
      expect(result.more!.start, equals('15610547826970000'));
      expect(result.more!.count, equals(98));
    });
    test('.batch#fetchMessages default count for single channel', () async {
      when(
              path:
                  '/v3/history/sub-key/test/channel/my_channel?max=100&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'GET')
          .then(status: 200, body: _batchFetchMessagesSuccessResponse);
      await pubnub.batch.fetchMessages({'my_channel'});
    });
    test('.batch#fetchMessages default count for multiple channel', () async {
      when(
              path:
                  '/v3/history/sub-key/test/channel/ch1,ch2?max=25&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'GET')
          .then(status: 200, body: _batchFetchMessagesSuccessResponse);
      await pubnub.batch.fetchMessages({'ch1', 'ch2'});
    });

    test('.batch#fetchMessages with actions default count', () async {
      when(
              path:
                  '/v3/history-with-actions/sub-key/test/channel/ch1?max=25&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'GET')
          .then(
              status: 200, body: _batchFetchMessagesWithActionSuccessResponse);
      await pubnub.batch.fetchMessages({'ch1'}, includeMessageActions: true);
    });
    test('.batch#fetchMessages with include_meta', () async {
      when(
              path:
                  '/v3/history/sub-key/test/channel/my_channel?max=100&include_meta=true&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'GET')
          .then(status: 200, body: _batchFetchMessagesWithMetaSuccessResponse);
      var result =
          await pubnub.batch.fetchMessages({'my_channel'}, includeMeta: true);

      expect(result.channels['my_channel']![0].meta!['hello'], equals('world'));
    });

    test('.batch#fetchMessages with include_meta and null meta value',
        () async {
      when(
              path:
                  '/v3/history/sub-key/test/channel/my_channel?max=100&include_meta=true&include_message_type=true&include_uuid=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
              method: 'GET')
          .then(status: 200, body: _batchFetchMessagesWithMetaEmptyString);
      var result =
          await pubnub.batch.fetchMessages({'my_channel'}, includeMeta: true);
      expect(result.channels['my_channel']![0].meta, equals(null));
    });
  });
}
