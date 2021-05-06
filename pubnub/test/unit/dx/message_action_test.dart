import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/message_action.dart';

import '../net/fake_net.dart';
part './fixtures/message_action.dart';

void main() {
  late PubNub pubnub;

  group('DX [messageAction]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test',
              publishKey: 'test',
              uuid: UUID('test-uuid')),
          networking: FakeNetworkingModule());
    });
    test('add message action throws when type is empty', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var value = 'value';
      var type = '';
      var channel = 'test';
      expect(
          pubnub.addMessageAction(
              type: type,
              value: value,
              channel: channel,
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('add message action throws when value is empty', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var value = '';
      var type = 'type';
      var channel = 'test';
      expect(
          pubnub.addMessageAction(
              type: type,
              value: value,
              channel: channel,
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('add message action throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      var channel = 'test';
      expect(
          pubnub.addMessageAction(
              type: actionType,
              value: actionValue,
              channel: channel,
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('add message action should give valid response type', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
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
              type: actionType,
              value: actionValue,
              channel: 'test',
              timetoken: messageTimetoken),
          isA<AddMessageActionResult>());
    });

    test('add message action failed to publish response', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      when(
        method: 'POST',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _addMessageActionBody,
      ).then(status: 207, body: _failedToPublishErrorResponse);

      expect(
          pubnub.addMessageAction(
              type: actionType,
              value: actionValue,
              channel: 'test',
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<PubNubException>()));
    });

    test('add message action invalid parameter response (400)', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      when(
        method: 'POST',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _addMessageActionBody,
      ).then(status: 400, body: _invalidParameterErrorResponse);
      expect(
          pubnub.addMessageAction(
              type: actionType,
              value: actionValue,
              channel: 'test',
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<PubNubException>()));
    });
    test('add message action invalid parameter response (403)', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      when(
        method: 'POST',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
        body: _addMessageActionBody,
      ).then(status: 403, body: _unauthorizeErrorResponse);
      expect(
          pubnub.addMessageAction(
              type: actionType,
              value: actionValue,
              channel: 'test',
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<PubNubException>()));
    });

    test('fetch message action throws when channel is empty', () async {
      expect(pubnub.fetchMessageActions(''),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('fetch message action returns valid response', () async {
      when(
              method: 'GET',
              path:
                  'v1/message-actions/test/channel/test?pnsdk=PubNub-Dart%2F${PubNub.version}&limit=100&uuid=test-uuid')
          .then(status: 200, body: _fetchMessageActionsResponse);

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
            'v1/message-actions/test/channel/test?pnsdk=PubNub-Dart%2F${PubNub.version}&limit=100&uuid=test-uuid',
      ).then(status: 200, body: _fetchMessageActionsResponseWithMoreField);
      var response = await pubnub.fetchMessageActions('test');
      expect(response.actions.length, 1);
      expect(response.moreActions, isA<MoreAction>());
    });

    test('fetch message action returns Error', () async {
      when(
        method: 'GET',
        path:
            'v1/message-actions/test/channel/test?pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 400, body: _fetchMessageActionError);

      expect(pubnub.fetchMessageActions('test'), throwsA(anything));
    });

    test('delete message action throws when channel is empty', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var channel = '';
      var actionTimetoken = Timetoken(BigInt.from(15645905639093361));

      expect(
          pubnub.deleteMessageAction(channel,
              messageTimetoken: messageTimetoken,
              actionTimetoken: actionTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('delete message actions throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var channel = 'test';
      var actionTimetoken = Timetoken(BigInt.from(15645905639093361));
      expect(
          pubnub.deleteMessageAction(channel,
              messageTimetoken: messageTimetoken,
              actionTimetoken: actionTimetoken),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('delete message action returns valid response', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var channel = 'test';
      var actionTimetoken = Timetoken(BigInt.from(15645905639093361));

      when(
        method: 'DELETE',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050/action/15645905639093361?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 200, body: _deleteMessageActionResponse);

      expect(
          await pubnub.deleteMessageAction(channel,
              messageTimetoken: messageTimetoken,
              actionTimetoken: actionTimetoken),
          isA<DeleteMessageActionResult>());
    });

    test('delete message action returns error response', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var channel = 'test';
      var actionTimetoken = Timetoken(BigInt.from(15645905639093361));
      when(
        method: 'DELETE',
        path:
            'v1/message-actions/test/channel/test/message/15610547826970050/action/15645905639093361?uuid=test-uuid&pnsdk=PubNub-Dart%2F${PubNub.version}',
      ).then(status: 403, body: _unauthorizeErrorResponse);
      expect(
          pubnub.deleteMessageAction(channel,
              messageTimetoken: messageTimetoken,
              actionTimetoken: actionTimetoken),
          throwsA(TypeMatcher<PubNubException>()));
    });
  });
}
