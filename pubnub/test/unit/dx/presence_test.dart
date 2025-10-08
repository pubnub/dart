import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/dx/presence/presence.dart';

import '../net/fake_net.dart';
part './fixtures/presence.dart';

void main() {
  PubNub? pubnub;

  group('DX [presence]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'demo', publishKey: 'demo', userId: UserId('test')),
          networking: FakeNetworkingModule());
    });

    group('MAXIMUM_COUNT constant', () {
      test('MAXIMUM_COUNT should be defined as 1000', () {
        expect(MAXIMUM_COUNT, equals(1000));
      });
    });

    group('hereNow method', () {
      test('hereNow throws if there is no available keyset', () async {
        pubnub?.keysets.remove('default');
        expect(pubnub?.hereNow(), throwsA(TypeMatcher<KeysetException>()));
      });

      test('hereNow uses MAXIMUM_COUNT as default limit', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSuccessResponse);

        final result = await pubnub!.hereNow();
        expect(result.totalOccupancy, equals(2));
        expect(result.totalChannels, equals(1));
      });

      test('hereNow accepts custom limit within maximum', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?uuid=test&disable_uuids=0&limit=500',
        ).then(status: 200, body: _hereNowSuccessResponse);

        final result = await pubnub!.hereNow(limit: 500);
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow caps limit to MAXIMUM_COUNT when exceeded', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSuccessResponse);

        // Even though we pass 1500, it should be capped to 1000
        final result = await pubnub!.hereNow(limit: 1500);
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow with single channel', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/test-channel?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSingleChannelResponse);

        final result = await pubnub!.hereNow(channels: {'test-channel'});
        expect(result.totalOccupancy, equals(1));
        expect(result.channels.containsKey('test-channel'), isTrue);
      });

      test('hereNow with multiple channels', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/channel1,channel2?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowMultiChannelResponse);

        final result =
            await pubnub!.hereNow(channels: {'channel1', 'channel2'});
        expect(result.totalOccupancy, equals(3));
        expect(result.totalChannels, equals(2));
      });

      test('hereNow with channel groups', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?channel-group=group1,group2&uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSuccessResponse);

        final result =
            await pubnub!.hereNow(channelGroups: {'group1', 'group2'});
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow with StateInfo.none', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/test-channel?uuid=test&limit=1000',
        ).then(status: 200, body: _hereNowNoUuidsResponse);

        final result = await pubnub!.hereNow(
          channels: {'test-channel'},
          stateInfo: StateInfo.none,
        );
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow with StateInfo.all', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/test-channel?uuid=test&disable_uuids=0&state=1&limit=1000',
        ).then(status: 200, body: _hereNowWithStateResponse);

        final result = await pubnub!.hereNow(
          channels: {'test-channel'},
          stateInfo: StateInfo.all,
        );
        expect(result.totalOccupancy, equals(1));
        expect(result.channels['test-channel']?.uuids.isNotEmpty, isTrue);
      });

      test('hereNow with StateInfo.onlyUUIDs (default)', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/test-channel?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSingleChannelResponse);

        final result = await pubnub!.hereNow(
          channels: {'test-channel'},
          stateInfo: StateInfo.onlyUUIDs,
        );
        expect(result.totalOccupancy, equals(1));
      });

      test('hereNow with custom keyset', () async {
        final customKeyset = Keyset(
          subscribeKey: 'custom-sub-key',
          publishKey: 'custom-pub-key',
          userId: UserId('custom-uuid'),
        );
        pubnub!.keysets.add('custom', customKeyset);

        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/custom-sub-key/channel/,?uuid=custom-uuid&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSuccessResponse);

        final result = await pubnub!.hereNow(using: 'custom');
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow with limit of 1 (minimum)', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?uuid=test&disable_uuids=0&limit=1',
        ).then(status: 200, body: _hereNowSuccessResponse);

        final result = await pubnub!.hereNow(limit: 1);
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow with limit exactly at MAXIMUM_COUNT', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSuccessResponse);

        final result = await pubnub!.hereNow(limit: MAXIMUM_COUNT);
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow caps limit when significantly exceeding maximum', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowSuccessResponse);

        // Test with a very large limit
        final result = await pubnub!.hereNow(limit: 99999);
        expect(result.totalOccupancy, equals(2));
      });

      test('hereNow handles empty channel response', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/empty-channel?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowEmptyChannelResponse);

        final result = await pubnub!.hereNow(channels: {'empty-channel'});
        expect(result.totalOccupancy, equals(0));
      });

      test('hereNow handles error response', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/,?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 403, body: _hereNowErrorResponse);

        expect(
          () async => await pubnub!.hereNow(),
          throwsA(TypeMatcher<PubNubException>()),
        );
      });

      test('hereNow without offset parameter', () async {
        when(
          method: 'GET',
          path:
              '/v2/presence/sub_key/demo/channel/test,my_channel?uuid=test&disable_uuids=0&limit=1000',
        ).then(status: 200, body: _hereNowWithOutNextOffsetResponse);

        final hereNowResponse = await pubnub!.hereNow(
          channels: {'test', 'my_channel'},
        );
        expect(hereNowResponse.nextOffset, equals(null));
      });
    });

    test('hereNow with limit and offset parameter', () async {
      when(
        method: 'GET',
        path:
            '/v2/presence/sub_key/demo/channel/test,my_channel?uuid=test&disable_uuids=0&limit=3&offset=1',
      ).then(status: 200, body: _hereNowWithOutNextOffsetLastPage);

      final hereNowResponse = await pubnub!.hereNow(
        channels: {'test', 'my_channel'},
        limit: 3,
        offset: 1,
      );
      expect(hereNowResponse.nextOffset, equals(null));
    });

    test('hereNow with less limit value parameter', () async {
      when(
        method: 'GET',
        path:
            '/v2/presence/sub_key/demo/channel/test,my_channel?uuid=test&disable_uuids=0&limit=2',
      ).then(status: 200, body: _hereNowWithOffsetRequired);

      final hereNowResponse =
          await pubnub!.hereNow(channels: {'test', 'my_channel'}, limit: 2);
      expect(hereNowResponse.nextOffset, equals(2));
    });

    test(
        'hereNow with multichannel less limit value parameter, uneven presence',
        () async {
      when(
        method: 'GET',
        path:
            '/v2/presence/sub_key/demo/channel/test,my_channel?uuid=test&disable_uuids=0&limit=2&offset=1',
      ).then(status: 200, body: _hereNowWithOffsetRequiredUnevenCount);

      final hereNowResponse = await pubnub!
          .hereNow(channels: {'test', 'my_channel'}, limit: 2, offset: 1);
      expect(hereNowResponse.nextOffset, equals(3));
    });

    test('hereNow with single channel default limit offset', () async {
      when(
        method: 'GET',
        path:
            '/v2/presence/sub_key/demo/channel/test?uuid=test&disable_uuids=0&limit=1000',
      ).then(status: 200, body: _hereNowSingleChannelResponse4Occupancies);

      final hereNowResponse = await pubnub!.hereNow(channels: {'test'});
      expect(hereNowResponse.nextOffset, equals(null));
      expect(hereNowResponse.totalOccupancy, equals(4));
    });

    test('hereNow with single channel, nextOffset in the response', () async {
      when(
        method: 'GET',
        path:
            '/v2/presence/sub_key/demo/channel/test?uuid=test&disable_uuids=0&limit=2',
      ).then(
          status: 200, body: _hereNowSingleChannelResponse4OccupanciesLimit2);

      final hereNowResponse =
          await pubnub!.hereNow(channels: {'test'}, limit: 2);
      expect(hereNowResponse.nextOffset, equals(2));
      expect(hereNowResponse.totalOccupancy, equals(4));
    });

    test('hereNow with single channel with  offset, nextOffset in the response',
        () async {
      when(
        method: 'GET',
        path:
            '/v2/presence/sub_key/demo/channel/test?uuid=test&disable_uuids=0&limit=2&offset=1',
      ).then(
          status: 200,
          body: _hereNowSingleChannelResponse4OccupanciesLimit2Offset1);

      final hereNowResponse =
          await pubnub!.hereNow(channels: {'test'}, limit: 2, offset: 1);
      expect(hereNowResponse.nextOffset, equals(3));
      expect(hereNowResponse.totalOccupancy, equals(4));
    });

    test(
        'hereNow with single channel in the response exact users count matches with limit',
        () async {
      when(
        method: 'GET',
        path:
            '/v2/presence/sub_key/demo/channel/test?uuid=test&disable_uuids=0&limit=2',
      ).then(status: 200, body: _hereNowSingleChannelsResponseMatchesLimit);

      final hereNowResponse =
          await pubnub!.hereNow(channels: {'test'}, limit: 2);
      expect(hereNowResponse.nextOffset, equals(null));
      expect(hereNowResponse.totalOccupancy, equals(2));
    });

    group('HereNowParams', () {
      test('HereNowParams uses MAXIMUM_COUNT as default limit', () {
        final keyset = Keyset(
          subscribeKey: 'test-sub-key',
          publishKey: 'test-pub-key',
          userId: UserId('test-uuid'),
        );
        final params = HereNowParams(keyset);
        expect(params.limit, equals(MAXIMUM_COUNT));
      });

      test('HereNowParams accepts custom limit', () {
        final keyset = Keyset(
          subscribeKey: 'test-sub-key',
          publishKey: 'test-pub-key',
          userId: UserId('test-uuid'),
        );
        final params = HereNowParams(keyset, limit: 500);
        expect(params.limit, equals(500));
      });

      test('HereNowParams toJson includes limit', () {
        final keyset = Keyset(
          subscribeKey: 'test-sub-key',
          publishKey: 'test-pub-key',
          uuid: UUID('test-uuid'),
        );
        final params = HereNowParams(keyset, limit: 750);
        final json = params.toJson();
        expect(json['limit'], equals(750));
      });

      test('HereNowParams toRequest includes limit in query parameters', () {
        final keyset = Keyset(
          subscribeKey: 'test-sub-key',
          publishKey: 'test-pub-key',
          uuid: UUID('test-uuid'),
        );
        final params = HereNowParams(keyset, limit: 250);
        final request = params.toRequest();
        expect(request.uri?.queryParameters['limit'], equals('250'));
      });

      test('HereNowParams with channels and channel groups', () {
        final keyset = Keyset(
          subscribeKey: 'test-sub-key',
          publishKey: 'test-pub-key',
          userId: UserId('test-uuid'),
        );
        final params = HereNowParams(
          keyset,
          channels: {'ch1', 'ch2'},
          channelGroups: {'cg1', 'cg2'},
          limit: 100,
        );
        final request = params.toRequest();
        expect(request.uri?.pathSegments.contains('ch1,ch2'), isTrue);
        expect(
            request.uri?.queryParameters['channel-group'], equals('cg1,cg2'));
        expect(request.uri?.queryParameters['limit'], equals('100'));
      });

      test('HereNowParams with different StateInfo values', () {
        final keyset = Keyset(
          subscribeKey: 'test-sub-key',
          publishKey: 'test-pub-key',
          userId: UserId('test-uuid'),
        );

        // Test StateInfo.all
        final paramsAll = HereNowParams(keyset, stateInfo: StateInfo.all);
        final requestAll = paramsAll.toRequest();
        expect(requestAll.uri?.queryParameters['disable_uuids'], equals('0'));
        expect(requestAll.uri?.queryParameters['state'], equals('1'));

        // Test StateInfo.onlyUUIDs
        final paramsUUIDs =
            HereNowParams(keyset, stateInfo: StateInfo.onlyUUIDs);
        final requestUUIDs = paramsUUIDs.toRequest();
        expect(requestUUIDs.uri?.queryParameters['disable_uuids'], equals('0'));
        expect(requestUUIDs.uri?.queryParameters.containsKey('state'), isFalse);

        // Test StateInfo.none
        final paramsNone = HereNowParams(keyset, stateInfo: StateInfo.none);
        final requestNone = paramsNone.toRequest();
        expect(requestNone.uri?.queryParameters.containsKey('disable_uuids'),
            isFalse);
        expect(requestNone.uri?.queryParameters.containsKey('state'), isFalse);
      });
    });

    group('ChannelOccupancy and OccupantInfo', () {
      test('ChannelOccupancy.fromJson parses correctly with UUIDs only', () {
        final json = {
          'occupancy': 2,
          'uuids': ['user1', 'user2']
        };
        final occupancy = ChannelOccupancy.fromJson('test-channel', json);
        expect(occupancy.channelName, equals('test-channel'));
        expect(occupancy.count, equals(2));
        expect(occupancy.uuids.length, equals(2));
        expect(occupancy.uuids.containsKey('user1'), isTrue);
        expect(occupancy.uuids.containsKey('user2'), isTrue);
      });

      test('ChannelOccupancy.fromJson parses correctly with state', () {
        final json = {
          'occupancy': 1,
          'uuids': [
            {
              'uuid': 'user1',
              'state': {'mood': 'happy', 'status': 'online'}
            }
          ]
        };
        final occupancy = ChannelOccupancy.fromJson('test-channel', json);
        expect(occupancy.channelName, equals('test-channel'));
        expect(occupancy.count, equals(1));
        expect(occupancy.uuids['user1']?.state?['mood'], equals('happy'));
        expect(occupancy.uuids['user1']?.state?['status'], equals('online'));
      });

      test('ChannelOccupancy.fromJson handles empty UUIDs', () {
        final json = {'occupancy': 0, 'uuids': null};
        final occupancy = ChannelOccupancy.fromJson('empty-channel', json);
        expect(occupancy.channelName, equals('empty-channel'));
        expect(occupancy.count, equals(0));
        expect(occupancy.uuids.isEmpty, isTrue);
      });

      test('OccupantInfo.fromJson parses correctly', () {
        final json = {
          'uuid': 'test-user',
          'state': {'location': 'office'}
        };
        final occupant = OccupantInfo.fromJson(json);
        expect(occupant.uuid, equals('test-user'));
        expect(occupant.state?['location'], equals('office'));
      });
    });

    group('HereNowResult', () {
      test('HereNowResult.fromJson parses multi-channel response', () {
        final json = {
          'status': 200,
          'message': 'OK',
          'payload': {
            'total_occupancy': 3,
            'total_channels': 2,
            'channels': {
              'channel1': {
                'occupancy': 2,
                'uuids': ['user1', 'user2']
              },
              'channel2': {
                'occupancy': 1,
                'uuids': ['user3']
              }
            }
          }
        };
        final result = HereNowResult.fromJson(json);
        expect(result.totalOccupancy, equals(3));
        expect(result.totalChannels, equals(2));
        expect(result.channels.length, equals(2));
        expect(result.channels['channel1']?.count, equals(2));
        expect(result.channels['channel2']?.count, equals(1));
      });

      test('HereNowResult.fromJson parses single-channel response', () {
        final json = {
          'status': 200,
          'message': 'OK',
          'occupancy': 1,
          'uuids': ['single-user']
        };
        final result =
            HereNowResult.fromJson(json, channelName: 'single-channel');
        expect(result.totalOccupancy, equals(1));
        expect(result.totalChannels, equals(1));
        expect(result.channels['single-channel']?.count, equals(1));
        expect(
            result.channels['single-channel']?.uuids.containsKey('single-user'),
            isTrue);
      });
    });
  });
}
