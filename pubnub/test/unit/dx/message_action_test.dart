import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import 'package:pubnub/src/dx/_utils/utils.dart';

import '../net/fake_net.dart';

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

    test('fetch message action throws when channel is empty', () async {
      expect(pubnub.fetchMessageActions(''),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('fetch message actions throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var channel = 'test';
      expect(pubnub.fetchMessageActions(channel),
          throwsA(TypeMatcher<KeysetException>()));
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
  });
}
