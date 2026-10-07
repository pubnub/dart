import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

void main() {
  group('DataSync models Input.toJson', () {
    test('EntityInput uses the wire names and omits unset keys', () {
      expect(EntityInput(className: 'Customer', classVersion: 1).toJson(),
          equals({'entityClass': 'Customer', 'entityClassVersion': 1}));
      expect(
          EntityInput(
              id: 'entity-1',
              className: 'Customer',
              classVersion: 1,
              classLevel: ClassLevel.subKey,
              status: 'active',
              payload: {'name': 'Alice'}).toJson(),
          equals({
            'id': 'entity-1',
            'entityClass': 'Customer',
            'entityClassVersion': 1,
            'entityClassLevel': 'SubKey',
            'status': 'active',
            'payload': {'name': 'Alice'},
          }));
    });

    test('UserInput and ChannelInput send entityClass only when set', () {
      expect(UserInput(classVersion: 1).toJson(),
          equals({'entityClassVersion': 1}));
      expect(ChannelInput(classVersion: 1).toJson(),
          equals({'entityClassVersion': 1}));
      expect(
          UserInput(
              id: 'user-1',
              classVersion: 1,
              classLevel: ClassLevel.global,
              status: 'active',
              payload: {'firstName': 'Alice'}).toJson(),
          equals({
            'id': 'user-1',
            'entityClassVersion': 1,
            'entityClassLevel': 'Global',
            'status': 'active',
            'payload': {'firstName': 'Alice'},
          }));
      expect(ChannelInput(className: 'Group', classVersion: 2).toJson(),
          equals({'entityClass': 'Group', 'entityClassVersion': 2}));
    });

    test('RelationshipInput uses the wire names', () {
      expect(
          RelationshipInput(
                  entityAId: 'a',
                  entityBId: 'b',
                  className: 'R',
                  classVersion: 1)
              .toJson(),
          equals({
            'entityAId': 'a',
            'entityBId': 'b',
            'relationshipClass': 'R',
            'relationshipClassVersion': 1,
          }));
    });

    test('MembershipInput never sends relationshipClass', () {
      expect(
          MembershipInput(
              id: 'membership-1',
              channelId: 'channel-1',
              userId: 'user-1',
              classVersion: 1,
              status: 'active',
              payload: {'role': 'member'}).toJson(),
          equals({
            'id': 'membership-1',
            'channelId': 'channel-1',
            'userId': 'user-1',
            'relationshipClassVersion': 1,
            'status': 'active',
            'payload': {'role': 'member'},
          }));
    });

    test('Update classes carry the version, status and payload only', () {
      var expectedEntity = {
        'entityClassVersion': 1,
        'status': 's',
        'payload': {'a': 1}
      };
      var expectedRelationship = {
        'relationshipClassVersion': 1,
        'status': 's',
        'payload': {'a': 1}
      };
      expect(
          EntityUpdate(classVersion: 1, status: 's', payload: {'a': 1})
              .toJson(),
          equals(expectedEntity));
      expect(
          UserUpdate(classVersion: 1, status: 's', payload: {'a': 1}).toJson(),
          equals(expectedEntity));
      expect(
          ChannelUpdate(classVersion: 1, status: 's', payload: {'a': 1})
              .toJson(),
          equals(expectedEntity));
      expect(
          RelationshipUpdate(classVersion: 1, status: 's', payload: {'a': 1})
              .toJson(),
          equals(expectedRelationship));
      expect(
          MembershipUpdate(classVersion: 1, status: 's', payload: {'a': 1})
              .toJson(),
          equals(expectedRelationship));
      expect(EntityUpdate(classVersion: 3).toJson(),
          equals({'entityClassVersion': 3}));
    });
  });

  group('DataSync models Record.fromJson', () {
    test('EntityRecord reads every field', () {
      var record = EntityRecord.fromJson(entityObject());
      expect(record.id, equals('customer-43508'));
      expect(record.entityClass, equals('Customer'));
      expect(record.entityClassVersion, equals(1));
      expect(record.entityClassLevel, equals('SubKey'));
      expect(record.status, equals('active'));
      expect(record.payload, equals(customerPayload('customer-43508')));
      expect(record.createdAt, equals('2026-09-07T07:25:20.309207Z'));
      expect(record.updatedAt, equals('2026-09-07T07:25:20.309207Z'));
      expect(record.eTag, equals('y26s8e'));
      expect(record.expiresAt, equals('2027-09-08T00:00:00Z'));
    });

    test('records accept the minimal set of required fields', () {
      var entity = EntityRecord.fromJson(
          {'id': 'e', 'entityClass': 'C', 'entityClassVersion': 1});
      expect(entity.status, isNull);
      expect(entity.payload, isNull);
      expect(entity.eTag, isNull);

      var membership = MembershipRecord.fromJson({
        'id': 'm',
        'channelId': 'c',
        'userId': 'u',
        'relationshipClass': 'Membership',
        'relationshipClassVersion': 1
      });
      expect(membership.payload, isNull);
    });

    test('RelationshipRecord and MembershipRecord read their endpoints', () {
      var relationship = RelationshipRecord.fromJson(relationshipObject());
      expect(relationship.entityAId, equals('customer-20648'));
      expect(relationship.entityBId, equals('loanquote-23500'));
      expect(relationship.relationshipClass, equals('REQUESTED_BY'));

      var membership = MembershipRecord.fromJson(membershipObject());
      expect(membership.channelId, equals('JSchannel-46429'));
      expect(membership.userId, equals('user-97219'));
      expect(membership.relationshipClass, equals('Membership'));
    });

    test('UserRecord and ChannelRecord read the entity class fields', () {
      var user = UserRecord.fromJson(userObject());
      expect(user.entityClass, equals('User'));
      expect(user.entityClassLevel, equals('Global'));

      var channel = ChannelRecord.fromJson(channelObject());
      expect(channel.entityClass, equals('Channel'));
      expect(channel.payload, equals(channelPayload()));
    });
  });

  group('DataSync models lenient optional fields', () {
    test('optional fields of an unexpected type are treated as absent', () {
      var record = EntityRecord.fromJson({
        'id': 'e',
        'entityClass': 'C',
        'entityClassVersion': 1,
        'status': 7,
        'payload': 'not-a-map',
        'eTag': ['x'],
      });

      expect(record.status, isNull);
      expect(record.payload, isNull);
      expect(record.eTag, isNull);
    });

    test('a required field of another type is a malformed response', () {
      expect(
          () => RelationshipRecord.fromJson(
              relationshipObject({'relationshipClassVersion': '1'})),
          throwsA(isA<MalformedResponseException>()));
    });
  });

  group('DataSync models malformed responses', () {
    late PubNub pubnub;

    setUp(() {
      pubnub = newClient();
    });

    // Regression for B7: required record fields are hard casts, so a response without
    // `entityClassVersion` fails with a raw TypeError.
    test('a record missing a required field is a malformed response', () async {
      when(method: 'GET', path: dsPath('entities', id: 'e')).then(
          status: 200, body: dataBody({'id': 'e', 'entityClass': 'Customer'}));

      await expectLater(pubnub.dataSync.getEntity('e'),
          throwsA(isA<MalformedResponseException>()));
    });

    // Regression for B8: a single-record response without `data` fails with a raw error.
    test('a response without data is a malformed response', () async {
      when(method: 'GET', path: dsPath('entities', id: 'e'))
          .then(status: 200, body: '{}');

      await expectLater(pubnub.dataSync.getEntity('e'),
          throwsA(isA<MalformedResponseException>()));
    });
  });
}
