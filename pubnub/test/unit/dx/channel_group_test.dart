import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import '../net/fake_net.dart';

part './fixtures/channel_group.dart';

void main() {
  PubNub? pubnub;

  group('DX [channelGroups]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test', publishKey: 'test', userId: UserId('test')),
          networking: FakeNetworkingModule());
    });

    group('listChannels', () {
      test('listChannels should return channels for valid group', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 200, body: _listChannelsSuccessResponse);

        final result = await pubnub!.channelGroups.listChannels('cg1');

        expect(result, isA<ChannelGroupListChannelsResult>());
        expect(result.name, equals('cg1'));
        expect(result.channels.containsAll(['ch1', 'ch2', 'ch3']), isTrue);
        expect(result.channels.length, equals(3));
      });

      test('listChannels should return empty set for group with no channels',
          () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/empty_group?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 200, body: _listChannelsEmptyResponse);

        final result = await pubnub!.channelGroups.listChannels('empty_group');

        expect(result.channels.isEmpty, isTrue);
        expect(result.name, equals('empty_group'));
      });

      test('listChannels should throw KeysetException when no keyset available',
          () async {
        pubnub!.keysets.remove('default');

        expect(() => pubnub!.channelGroups.listChannels('cg1'),
            throwsA(TypeMatcher<KeysetException>()));
      });

      test('listChannels should throw ForbiddenException on 403 error',
          () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 403, body: _forbiddenErrorResponse);

        expect(pubnub!.channelGroups.listChannels('cg1'),
            throwsA(TypeMatcher<ForbiddenException>()));
      });

      test('listChannels should throw InvalidArgumentsException on 400 error',
          () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/invalid_group?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 400, body: _invalidArgumentsErrorResponse);

        expect(pubnub!.channelGroups.listChannels('invalid_group'),
            throwsA(TypeMatcher<InvalidArgumentsException>()));
      });

      test('listChannels should use custom keyset when provided', () async {
        var customKeyset = Keyset(
            subscribeKey: 'custom',
            publishKey: 'custom',
            userId: UserId('custom'));

        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/custom/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=custom',
        ).then(status: 200, body: _listChannelsSuccessResponse);

        final result = await pubnub!.channelGroups
            .listChannels('cg1', keyset: customKeyset);

        expect(result, isA<ChannelGroupListChannelsResult>());
        expect(result.name, equals('cg1'));
      });

      test('listChannels should use named keyset when specified', () async {
        var namedKeyset = Keyset(
            subscribeKey: 'named',
            publishKey: 'named',
            userId: UserId('named'));
        pubnub!.keysets.add('named', namedKeyset);

        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/named/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=named',
        ).then(status: 200, body: _listChannelsSuccessResponse);

        final result =
            await pubnub!.channelGroups.listChannels('cg1', using: 'named');

        expect(result, isA<ChannelGroupListChannelsResult>());
        expect(result.name, equals('cg1'));
      });
    });

    group('addChannels', () {
      test('addChannels should add channels to group successfully', () async {
        var channels = {'ch1', 'ch2'};

        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test&add=ch1%2Cch2&remove',
        ).then(status: 200, body: _addChannelsSuccessResponse);

        final result = await pubnub!.channelGroups.addChannels('cg1', channels);

        expect(result, isA<ChannelGroupChangeChannelsResult>());
      });

      test('addChannels should handle empty channel set', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test&add&remove',
        ).then(status: 200, body: _addChannelsSuccessResponse);

        final result =
            await pubnub!.channelGroups.addChannels('cg1', <String>{});

        expect(result, isA<ChannelGroupChangeChannelsResult>());
      });

      test('addChannels should handle multiple channels (within limit)',
          () async {
        var channels = List.generate(100, (i) => 'ch$i').toSet();
        var expectedChannelsParam = channels.join('%2C');

        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test&add=$expectedChannelsParam&remove',
        ).then(status: 200, body: _addChannelsSuccessResponse);

        final result = await pubnub!.channelGroups.addChannels('cg1', channels);

        expect(result, isA<ChannelGroupChangeChannelsResult>());
      });

      test('addChannels should throw KeysetException when no keyset', () async {
        pubnub!.keysets.remove('default');

        expect(() => pubnub!.channelGroups.addChannels('cg1', {'ch1'}),
            throwsA(TypeMatcher<KeysetException>()));
      });

      test('addChannels should handle 403 Forbidden error', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test&add=ch1&remove',
        ).then(status: 403, body: _forbiddenErrorResponse);

        expect(pubnub!.channelGroups.addChannels('cg1', {'ch1'}),
            throwsA(TypeMatcher<ForbiddenException>()));
      });
    });

    group('removeChannels', () {
      test('removeChannels should remove channels from group successfully',
          () async {
        var channels = {'ch1', 'ch2'};

        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test&add&remove=ch1%2Cch2',
        ).then(status: 200, body: _removeChannelsSuccessResponse);

        final result =
            await pubnub!.channelGroups.removeChannels('cg1', channels);

        expect(result, isA<ChannelGroupChangeChannelsResult>());
      });

      test('removeChannels should succeed even for non-existent channels',
          () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test&add&remove=nonexistent',
        ).then(status: 200, body: _removeChannelsSuccessResponse);

        final result =
            await pubnub!.channelGroups.removeChannels('cg1', {'nonexistent'});

        expect(result, isA<ChannelGroupChangeChannelsResult>());
      });

      test('removeChannels should handle empty channel set', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test&add&remove',
        ).then(status: 200, body: _removeChannelsSuccessResponse);

        final result =
            await pubnub!.channelGroups.removeChannels('cg1', <String>{});

        expect(result, isA<ChannelGroupChangeChannelsResult>());
      });

      test('removeChannels should throw KeysetException when no keyset',
          () async {
        pubnub!.keysets.remove('default');

        expect(() => pubnub!.channelGroups.removeChannels('cg1', {'ch1'}),
            throwsA(TypeMatcher<KeysetException>()));
      });
    });

    group('delete', () {
      test('delete should remove entire channel group successfully', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1/remove?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 200, body: _deleteChannelGroupSuccessResponse);

        final result = await pubnub!.channelGroups.delete('cg1');

        expect(result, isA<ChannelGroupDeleteResult>());
      });

      test('delete should succeed for non-existent group', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/nonexistent_group/remove?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 200, body: _deleteChannelGroupSuccessResponse);

        final result = await pubnub!.channelGroups.delete('nonexistent_group');

        expect(result, isA<ChannelGroupDeleteResult>());
      });

      test('delete should throw KeysetException when no keyset', () async {
        pubnub!.keysets.remove('default');

        expect(() => pubnub!.channelGroups.delete('cg1'),
            throwsA(TypeMatcher<KeysetException>()));
      });

      test('delete should handle 403 Forbidden error', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1/remove?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 403, body: _forbiddenErrorResponse);

        expect(pubnub!.channelGroups.delete('cg1'),
            throwsA(TypeMatcher<ForbiddenException>()));
      });
    });

    group('Error Handling', () {
      test('should handle network timeout gracefully', () async {
        // Clear the mock queue and don't set up any response
        // This will trigger the MockException in FakeNetworkingModule

        expect(pubnub!.channelGroups.listChannels('cg1'),
            throwsA(TypeMatcher<MockException>()));
      });

      test('should handle malformed JSON response', () async {
        when(
          method: 'GET',
          path:
              '/v1/channel-registration/sub-key/test/channel-group/cg1?pnsdk=PubNub-Dart%2F${PubNub.version}&uuid=test',
        ).then(status: 200, body: _malformedJsonResponse);

        expect(pubnub!.channelGroups.listChannels('cg1'),
            throwsA(TypeMatcher<ParserException>()));
      });
    });

    tearDown(() {
      pubnub = null;
    });
  });
}
