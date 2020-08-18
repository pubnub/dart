import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/message_action.dart';

import '../net/fake_net.dart';
part './fixtures/message_action.dart';

void main() {
  PubNub pubnub;

  group('DX [messageAction]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            Keyset(
                subscribeKey: 'test',
                publishKey: 'test',
                uuid: UUID('test-uuid')),
            name: 'default',
            useAsDefault: true);
    });
    test('add message action throws when type is empty', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var value = 'value';
      var type = '';
      var channel = 'test';
      expect(pubnub.addMessageAction(type, value, channel, messageTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('add message action throws when value is empty', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var value = '';
      var type = 'type';
      var channel = 'test';
      expect(pubnub.addMessageAction(type, value, channel, messageTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('add message action throws when message timetoken is null', () async {
      var value = 'value';
      var type = 'type';
      var channel = 'test';
      expect(pubnub.addMessageAction(type, value, channel, null),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('add message action throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var messageTimetoken = Timetoken(15610547826970050);
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      var channel = 'test';
      expect(
          pubnub.addMessageAction(
              actionType, actionValue, channel, messageTimetoken),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('add message action should give valid response type', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      when(
        method: 'POST',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _addMessageActionBody,
      ).then(status: 200, body: _addMessageActionResponse);
      expect(
          await pubnub.addMessageAction(
              actionType, actionValue, 'test', messageTimetoken),
          isA<AddMessageActionResult>());
    });

    test('add message action failed to publish response', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      when(
        method: 'POST',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _addMessageActionBody,
      ).then(status: 200, body: _failedToPublishErrorResponse);
      var response = await pubnub.addMessageAction(
          actionType, actionValue, 'test', messageTimetoken);
      expect(response.status, 207);
    });

    test('add message action invalid parameter response', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      when(
        method: 'POST',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _addMessageActionBody,
      ).then(status: 200, body: _invalidParameterErrorResponse);
      var response = await pubnub.addMessageAction(
          actionType, actionValue, 'test', messageTimetoken);
      expect(response.status, 400);
    });
    test('add message action invalid parameter response', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      when(
        method: 'POST',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _addMessageActionBody,
      ).then(status: 200, body: _unauthorizeErrorResponse);
      var response = await pubnub.addMessageAction(
          actionType, actionValue, 'test', messageTimetoken);
      expect(response.status, 403);
    });

    test('fetch message action throws when channel is empty', () async {
      expect(pubnub.fetchMessageActions(''),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('fetch message action returns valid response', () async {
      when(
        method: 'GET',
        path:
            'v1/message-actions/test/channel/test?pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _fetchMessageActionsResponse);

      expect(await pubnub.fetchMessageActions('test'),
          isA<FetchMessageActionsResult>());
    });
    test('fetch message actions throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var channel = 'test';
      expect(pubnub.fetchMessageActions(channel),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('fetch message action returns valid response with multiple page',
        () async {
      when(
        method: 'GET',
        path:
            'v1/message-actions/test/channel/test?pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _fetchMessageActionsResponsePage1);
      when(
        method: 'GET',
        path:
            'v1/message-actions/test/channel/test?start=15610547826970050&end=15645905639093361&limit=2&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _fetchMessageActionsResponsePage2);
      var response = await pubnub.fetchMessageActions('test');
      expect(response.actions.length, 3);
    });

    test('fetch message action returns Error', () async {
      when(
        method: 'GET',
        path:
            'v1/message-actions/test/channel/test?pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _fetchMessageActionError);
      var response = await pubnub.fetchMessageActions('test');
      expect(response.status, 400);
    });

    test('delete message action throws when channel is empty', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var channel = '';
      var actionTimetoken = Timetoken(15645905639093361);

      expect(
          pubnub.deleteMessageAction(
              channel, messageTimetoken, actionTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('delete message action throws when message timetoken is null',
        () async {
      var channel = 'test';
      var actionTimetoken = Timetoken(15645905639093361);
      expect(pubnub.deleteMessageAction(channel, null, actionTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('delete message action throws when action timetoken is null',
        () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var channel = 'test';
      expect(pubnub.deleteMessageAction(channel, messageTimetoken, null),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('delete message actions throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var messageTimetoken = Timetoken(15610547826970050);
      var channel = 'test';
      var actionTimetoken = Timetoken(15645905639093361);
      expect(
          pubnub.deleteMessageAction(
              channel, messageTimetoken, actionTimetoken),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('delete message action returns valid response', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var channel = 'test';
      var actionTimetoken = Timetoken(15645905639093361);

      when(
        method: 'DELETE',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050/action/15645905639093361?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _deleteMessageActionResponse);

      expect(
          await pubnub.deleteMessageAction(
              channel, messageTimetoken, actionTimetoken),
          isA<DeleteMessageActionResult>());
    });

    test('delete message action returns error response', () async {
      var messageTimetoken = Timetoken(15610547826970050);
      var channel = 'test';
      var actionTimetoken = Timetoken(15645905639093361);
      when(
        method: 'DELETE',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050/action/15645905639093361?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _unauthorizeErrorResponse);
      var response = await pubnub.deleteMessageAction(
          channel, messageTimetoken, actionTimetoken);
      expect(response.status, 403);
    });
  });
}
