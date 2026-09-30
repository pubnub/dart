@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;
  late String userId;
  late String channelId;

  setUp(() async {
    pubnub = superClient();
    cleanup = Cleanup();
    userId = freshId('dartuser');
    channelId = freshId('dartchannel');
    await createUser(pubnub, cleanup, userId);
    await createChannel(pubnub, cleanup, channelId);
  });

  tearDown(() => cleanup.run());

  group('DataSync [membership] lifecycle', () {
    test('create, get, set, update and remove a membership', () async {
      var id = freshId('dartmembership');

      var created = await createMembership(pubnub, cleanup, id, userId,
          channelId, {'notificationsEnabled': true});
      expect(created.id, equals(id));
      expect(created.userId, equals(userId));
      expect(created.channelId, equals(channelId));
      expect(created.relationshipClass, equals(membershipClass));
      expect(created.relationshipClassVersion, equals(classVersion));
      expect(created.status, equals('active'));
      expectPayloadContains(created.payload, {'role': 'member'});

      var read = (await pubnub.dataSync.getMembership(id)).membership;
      expect(read.eTag, equals(created.eTag));

      var replaced = (await pubnub.dataSync.setMembership(
              id,
              MembershipUpdate(
                  classVersion: classVersion,
                  status: 'updated',
                  payload: membershipPayload({'role': 'moderator'}))))
          .membership;
      expect(replaced.status, equals('updated'));
      expect(replaced.payload!['role'], equals('moderator'));
      expect(replaced.userId, equals(userId));
      expect(replaced.channelId, equals(channelId));

      var patched = (await pubnub.dataSync.updateMembership(id,
              replace: {'/payload/role': 'admin'},
              ifMatchesEtag: replaced.eTag))
          .membership;
      expect(patched.payload!['role'], equals('admin'));

      await pubnub.dataSync.removeMembership(id);
      await expectLater(
          pubnub.dataSync.getMembership(id), throwsDataSync('DS-0100'));
    });

    test('a stale eTag is rejected with DS-0300', () async {
      var id = freshId('dartmembership');
      await createMembership(pubnub, cleanup, id, userId, channelId);

      await expectLater(
          pubnub.dataSync.updateMembership(id,
              replace: {'/payload/role': 'admin'}, ifMatchesEtag: 'stale'),
          throwsDataSync('DS-0300'));
    });

    test('a user that does not exist is rejected with DS-0100', () async {
      await expectLater(
          pubnub.dataSync.createMembership(MembershipInput(
              userId: freshId('dartnosuch'),
              channelId: channelId,
              classVersion: classVersion)),
          throwsDataSync('DS-0100'));
    });
  });

  group('DataSync [membership] getMemberships', () {
    late String otherChannelId;
    late String otherUserId;
    late List<String> ids;

    setUp(() async {
      otherChannelId = freshId('dartchannel');
      otherUserId = freshId('dartuser');
      await createChannel(pubnub, cleanup, otherChannelId);
      await createUser(pubnub, cleanup, otherUserId);
      ids = [
        freshId('dartmembership'),
        freshId('dartmembership'),
        freshId('dartmembership')
      ];
      await createMembership(pubnub, cleanup, ids[0], userId, channelId);
      await createMembership(pubnub, cleanup, ids[1], userId, otherChannelId);
      await createMembership(pubnub, cleanup, ids[2], otherUserId, channelId);
    });

    test('lists the memberships of one user across channels', () async {
      var result = await pubnub.dataSync.getMemberships(userId: userId);

      expect(result.memberships.map((m) => m.id),
          unorderedEquals([ids[0], ids[1]]));
      expect(result.memberships.map((m) => m.channelId).toSet(),
          equals({channelId, otherChannelId}));
    });

    test('lists the memberships of one channel across users', () async {
      var result = await pubnub.dataSync.getMemberships(channelId: channelId);

      expect(result.memberships.map((m) => m.id),
          unorderedEquals([ids[0], ids[2]]));
      expect(result.memberships.map((m) => m.userId).toSet(),
          equals({userId, otherUserId}));
    });

    test('pins one edge with both endpoints and the class version', () async {
      var result = await pubnub.dataSync.getMemberships(
          userId: userId, channelId: channelId, classVersion: classVersion);

      expect(result.memberships.map((m) => m.id), equals([ids[0]]));
    });

    test('pages through the memberships of a user', () async {
      var first =
          await pubnub.dataSync.getMemberships(userId: userId, limit: 1);
      expect(first.memberships, hasLength(1));
      expect(first.hasNext, isTrue);

      var second = await pubnub.dataSync
          .getMemberships(userId: userId, limit: 1, cursor: first.nextCursor);
      expect(second.memberships, hasLength(1));
      expect(second.memberships.single.id,
          isNot(equals(first.memberships.single.id)));
    });
  });
}
