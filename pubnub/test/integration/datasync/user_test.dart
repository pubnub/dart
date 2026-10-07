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

  group('DataSync [user] lifecycle', () {
    test('create, get, set, update and remove a user', () async {
      var id = freshId('dartuser');

      var created = await createUser(pubnub, cleanup, id, {'level': 'L3'});
      expect(created.id, equals(id));
      expect(created.entityClass, equals('User'));
      expect(created.entityClassVersion, equals(classVersion));
      expect(created.entityClassLevel, equals('Global'));
      expect(created.status, equals('active'));
      expectPayloadContains(created.payload, userPayload({'level': 'L3'}));

      var read = (await pubnub.dataSync.getUser(id)).user;
      expect(read.eTag, equals(created.eTag));

      var replaced = (await pubnub.dataSync.setUser(
              id,
              UserUpdate(
                  classVersion: classVersion,
                  status: 'inactive',
                  payload: userPayload({'level': 'L4'}))))
          .user;
      expect(replaced.status, equals('inactive'));
      expect(replaced.payload!['level'], equals('L4'));

      var patched = (await pubnub.dataSync.updateUser(id,
              replace: {'/payload/level': 'L5'}, ifMatchesEtag: replaced.eTag))
          .user;
      expect(patched.payload!['level'], equals('L5'));
      expect(patched.eTag, isNot(equals(replaced.eTag)));

      await pubnub.dataSync.removeUser(id);
      await expectLater(pubnub.dataSync.getUser(id), throwsDataSync('DS-0100'));
    });

    test('a stale eTag is rejected with DS-0300', () async {
      var id = freshId('dartuser');
      await createUser(pubnub, cleanup, id);

      await expectLater(
          pubnub.dataSync.setUser(id, UserUpdate(classVersion: classVersion),
              ifMatchesEtag: 'stale'),
          throwsDataSync('DS-0300'));
    });
  });

  group('DataSync [user] getUsers', () {
    test('filterFast and pagination over seeded users', () async {
      var marker = runMarker();
      var ids = <String>[];
      for (var i = 0; i < 3; i++) {
        var id = freshId('dartuser');
        await pubnub.dataSync.createUser(UserInput(
            id: id,
            classVersion: classVersion,
            status: marker,
            payload: userPayload()));
        cleanup.add(() => pubnub.dataSync.removeUser(id));
        ids.add(id);
      }

      var all = await pubnub.dataSync.getUsers(
          className: 'User',
          classVersion: classVersion,
          classLevel: ClassLevel.global,
          filterFast: "status == '$marker'");
      expect(all.users.map((u) => u.id), unorderedEquals(ids));

      var seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        var page = await pubnub.dataSync.getUsers(
            filterFast: "status == '$marker'",
            limit: 2,
            cursor: cursor,
            sort: 'createdAt:desc');
        seen.addAll(page.users.map((u) => u.id));
        cursor = page.hasNext ? page.nextCursor : null;
        pages++;
      } while (cursor != null && pages < 5);

      expect(pages, equals(2));
      expect(seen, equals(ids.reversed.toList()));
    });
  });
}
