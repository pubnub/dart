@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;

  setUp(() {
    pubnub = superClient();
    cleanup = Cleanup();
  });

  tearDown(() => cleanup.run());

  group('DataSync [channel] lifecycle', () {
    test('create, get, set, update and remove a channel', () async {
      var id = freshId('dartchannel');

      var created =
          await createChannel(pubnub, cleanup, id, {'memberCount': 3});
      expect(created.id, equals(id));
      expect(created.entityClass, equals('Channel'));
      expect(created.entityClassVersion, equals(classVersion));
      expect(created.entityClassLevel, equals('Global'));
      expect(created.status, equals('active'));
      expectPayloadContains(
          created.payload, channelPayload({'memberCount': 3}));

      var read = (await pubnub.dataSync.getChannel(id)).channel;
      expect(read.eTag, equals(created.eTag));

      var replaced = (await pubnub.dataSync.setChannel(
              id,
              ChannelUpdate(
                  classVersion: classVersion,
                  status: 'inactive',
                  payload: channelPayload({'memberCount': 4}))))
          .channel;
      expect(replaced.status, equals('inactive'));
      expect(replaced.payload!['memberCount'], equals(4));

      var patched = (await pubnub.dataSync.updateChannel(id,
              replace: {'/payload/memberCount': 5},
              ifMatchesEtag: replaced.eTag))
          .channel;
      expect(patched.payload!['memberCount'], equals(5));
      expect(patched.eTag, isNot(equals(replaced.eTag)));

      await pubnub.dataSync.removeChannel(id);
      await expectLater(
          pubnub.dataSync.getChannel(id), throwsDataSync('DS-0100'));
    });

    test('a stale eTag is rejected with DS-0300', () async {
      var id = freshId('dartchannel');
      await createChannel(pubnub, cleanup, id);

      await expectLater(
          pubnub.dataSync.setChannel(
              id, ChannelUpdate(classVersion: classVersion),
              ifMatchesEtag: 'stale'),
          throwsDataSync('DS-0300'));
    });
  });

  group('DataSync [channel] getChannels', () {
    test('filterFast and pagination over seeded channels', () async {
      var marker = runMarker();
      var ids = <String>[];
      for (var i = 0; i < 3; i++) {
        var id = freshId('dartchannel');
        await pubnub.dataSync.createChannel(ChannelInput(
            id: id,
            classVersion: classVersion,
            status: marker,
            payload: channelPayload()));
        cleanup.add(() => pubnub.dataSync.removeChannel(id));
        ids.add(id);
      }

      var all = await pubnub.dataSync.getChannels(
          className: 'Channel',
          classVersion: classVersion,
          classLevel: ClassLevel.global,
          filterFast: "status == '$marker'");
      expect(all.channels.map((c) => c.id), unorderedEquals(ids));

      var seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        var page = await pubnub.dataSync.getChannels(
            filterFast: "status == '$marker'",
            limit: 2,
            cursor: cursor,
            sort: 'createdAt:desc');
        seen.addAll(page.channels.map((c) => c.id));
        cursor = page.hasNext ? page.nextCursor : null;
        pages++;
      } while (cursor != null && pages < 5);

      expect(pages, equals(2));
      expect(seen, equals(ids.reversed.toList()));
    });
  });
}
