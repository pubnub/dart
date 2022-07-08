import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import 'package:pubnub/src/dx/channel/channel.dart';
import 'package:pubnub/src/dx/channel/channel_history.dart';

import '../net/fake_net.dart';
part './fixtures/channel.dart';

void main() {
  PubNub? pubnub;
  group('DX [channel]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test', publishKey: 'test', uuid: UUID('test')),
          networking: FakeNetworkingModule());
    });

    test('#channel should return an instance of Channel', () {
      var channel = pubnub!.channel('name');

      expect(channel, isA<Channel>());
    });

    group('[publish]', () {
      test('publish should delegate to Pubnub#publish', () async {
        var fakePubnub = FakePubNub();

        fakePubnub.returnWhen(
            #publish, Future.value(PublishResult.fromJson([1, '', '123'])));

        var keyset = Keyset(
            subscribeKey: 'test', publishKey: 'test', uuid: UUID('test'));
        var channel = Channel(fakePubnub, keyset, 'test');

        await channel.publish({'my': 'message'}, ttl: 60);

        var invocation = fakePubnub.invocations[0];

        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#publish));
        expect(
            invocation.positionalArguments,
            equals([
              'test',
              {'my': 'message'}
            ]));
        expect(
            invocation.namedArguments,
            equals({
              #keyset: keyset,
              #using: null,
              #storeMessage: null,
              #ttl: 60,
              #meta: null,
              #fire: null
            }));
      });
    });

    group('[history]', () {
      late Channel channel;
      setUp(() {
        channel = pubnub!.channel('test');
      });

      test('#messages should return an instance of ChannelHistory', () {
        var history = channel.messages();

        expect(history, isA<ChannelHistory>());
      });

      group('[ChannelHistory]', () {
        late ChannelHistory history;
        setUp(() {
          history = channel.messages();
        });

        test('#count should send correct request and return an int', () async {
          when(
            method: 'GET',
            path:
                'v3/history/sub-key/test/message-counts/test?timetoken=1&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
          ).then(status: 200, body: _historyMessagesCountResponse);

          var count = await history.count();

          expect(count, equals(42));
        });

        test('#delete should send correct request', () async {
          when(
            method: 'DELETE',
            path:
                'v3/history/sub-key/test/channel/test?uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
          ).then(status: 200, body: _historyMessagesDeleteResponse);

          await history.delete();
        });

        test('#fetch should send correct request', () async {
          when(
            method: 'GET',
            path:
                'v2/history/sub-key/test/channel/test?count=100&reverse=true&include_token=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
          ).then(status: 200, body: _historyMessagesFetchResponse);

          await history.fetch();

          expect(history.messages.length, equals(1));
        });
      });

      test('#history should return an instance of PaginatedChannelHistory', () {
        var history = channel.history();

        expect(history, isA<PaginatedChannelHistory>());
      });
      group('[PaginatedChannelHistory]', () {
        test('.hasMore should be true before calling #more', () {
          var history = channel.history();

          expect(history.hasMore, equals(true));
        });
        test('#more should fetch messages', () async {
          when(
            method: 'GET',
            path:
                'v2/history/sub-key/test/channel/test?count=100&reverse=false&include_token=true&uuid=test&pnsdk=PubNub-Dart%2F${PubNub.version}',
          ).then(status: 200, body: _historyMoreSuccessResponse);

          var history = channel.history();

          await history.more();

          expect(history.messages.length, equals(1));
          expect(history.startTimetoken?.value, equals(BigInt.from(10)));
          expect(history.endTimetoken?.value, equals(BigInt.from(20)));
        });
      });
    });
    group('[messageAction]', () {
      late Channel channel;
      late FakePubNub fakePubnub;
      late Keyset keyset;
      setUp(() {
        fakePubnub = FakePubNub();
        keyset = Keyset(
            subscribeKey: 'test', publishKey: 'test', uuid: UUID('test'));
        channel = Channel(fakePubnub, keyset, 'test');
      });
      test('fetchMessageActions should delegate to Pubnub#fetchMessageActions',
          () async {
        var startTimetoken = Timetoken(BigInt.from(15610547826970050));
        var endTimetoken = Timetoken(BigInt.from(15645905639093361));
        var limit = 5;

        fakePubnub.returnWhen(
          #fetchMessageActions,
          Future.value(FetchMessageActionsResult.fromJson({
            'status': 200,
            'data': [
              {
                'type': 'reaction',
                'value': 'smiley_face',
                'actionTimetoken': '15610547826970050',
                'messageTimetoken': '15610547826969050',
                'uuid': 'terryterry69420'
              }
            ]
          })),
        );

        await channel.fetchMessageActions(
            from: startTimetoken, to: endTimetoken, limit: limit);
        var invocation = fakePubnub.invocations[0];
        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#fetchMessageActions));
        expect(invocation.positionalArguments, equals(['test']));
        expect(
            invocation.namedArguments,
            equals({
              #from: startTimetoken,
              #to: endTimetoken,
              #limit: limit,
              #keyset: keyset,
              #using: null
            }));
      });
      test('addMessageAction should delegate to Pubnub#addMessageAction',
          () async {
        var type = 'type';
        var value = 'value';
        var messageTimetoken = Timetoken(BigInt.from(15610547826970050));

        fakePubnub.returnWhen(
          #addMessageAction,
          Future.value(AddMessageActionResult.fromJson({
            'status': 200,
            'data': {
              'type': 'reaction',
              'value': 'smiley_face',
              'actionTimetoken': '15610547826970050',
              'messageTimetoken': '15610547826969050',
              'uuid': 'terryterry69420'
            }
          })),
        );

        await channel.addMessageAction(
            type: type, value: value, timetoken: messageTimetoken);
        var invocation = fakePubnub.invocations[0];
        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#addMessageAction));
        expect(
            invocation.namedArguments,
            equals({
              #type: type,
              #value: value,
              #channel: 'test',
              #timetoken: messageTimetoken,
              #keyset: keyset,
              #using: null
            }));
      });
      test('deleteMessageAction should delegate to Pubnub#deleteMessageAction',
          () async {
        var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
        var actionTimetoken = Timetoken(BigInt.from(15645905639093361));

        fakePubnub.returnWhen(
          #deleteMessageAction,
          Future.value(
              DeleteMessageActionResult.fromJson({'status': 200, 'data': {}})),
        );

        await channel.deleteMessageAction(
            messageTimetoken: messageTimetoken,
            actionTimetoken: actionTimetoken);
        var invocation = fakePubnub.invocations[0];
        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#deleteMessageAction));
        expect(invocation.positionalArguments, equals(['test']));
        expect(
            invocation.namedArguments,
            equals({
              #messageTimetoken: messageTimetoken,
              #actionTimetoken: actionTimetoken,
              #keyset: keyset,
              #using: null
            }));
      });
    });
  });
}
