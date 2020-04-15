import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/core/keyset.dart';
import 'package:pubnub/src/net/exceptions.dart';
import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/dx/_endpoints/publish.dart';

import '../net/fake_net.dart';

part './fixtures/publish.dart';

void main() {
  PubNub pubnub;
  group('DX [publish]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'demo', publishKey: 'demo'),
            name: 'default', useAsDefault: true);
    });

    test('publish throws if channel name is an empty string', () async {
      expect(
          pubnub.publish('', 42), throwsA(TypeMatcher<InvariantException>()));
    });

    test('publish throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      expect(
          pubnub.publish('test', 42), throwsA(TypeMatcher<KeysetException>()));
    });

    test('publish returns PublishResult with correct data', () async {
      when(
          path: 'publish/demo/demo/0/test/0',
          method: 'POST',
          body: '{"hello":"world"}',
          then: FakeResult(_publishSuccessResponse));

      var response = await pubnub.publish('test', {'hello': 'world'});

      expect(response, isA<PublishResult>());
      expect(response.isError, equals(false));
      expect(response.description, equals('Sent'));
    });

    test('publish throws an exception when non-200 status code', () async {
      when(
          path: 'publish/demo/demo/0/test/0',
          method: 'POST',
          body: '{"hello":"world"}',
          throws: PubNubRequestFailureException(_publishFailureResponse));

      expect(pubnub.publish('test', {'hello': 'world'}),
          throwsA(TypeMatcher<PubNubException>()));
    });
  });
}
