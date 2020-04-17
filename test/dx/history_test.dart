import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/dx/_endpoints/history.dart';

import '../net/fake_net.dart';
part './fixtures/history.dart';

void main() {
  PubNub pubnub;
  group('DX [history]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'test', publishKey: 'test'),
            name: 'default', useAsDefault: true);
    });

    test('.batch#fetchMessages correctly fetches messages', () async {
      when(
        path:
            'v3/history/sub-key/test/channel/test-1,test-2?max=10&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: _batchFetchMessagesSuccessResponse);

      var result =
          await pubnub.batch.fetchMessages({'test-1', 'test-2'}, count: 10);

      expect(result.channels['test-1'], isA<List<BatchHistoryResultEntry>>());
      expect(result.channels['test-1'].length, equals(1));
      expect(result.channels['test-1'][0].message, equals(42));
      expect(result.channels['test-2'], isA<List<BatchHistoryResultEntry>>());
      expect(result.channels['test-2'].length, equals(1));
      expect(result.channels['test-2'][0].message, equals(10));
    });

    test('.batch#countMessages correctly fetches counts when passed in Set',
        () async {
      when(
        method: 'GET',
        path:
            'v3/history/sub-key/test/message-counts/test-1,test-2?timetoken=100&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _batchCountMessagesSuccessResponse);

      var result = await pubnub.batch
          .countMessages({'test-1', 'test-2'}, timetoken: Timetoken(100));

      expect(result.channels['test-1'], equals(42));
      expect(result.channels['test-2'], equals(10));
    });
  });
}
