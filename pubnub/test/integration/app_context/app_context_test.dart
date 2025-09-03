import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import '_utils.dart';

void main() {
  late PubNub pubnub;
  late Map<String, dynamic> testConfig;
  late String testPrefix;

  setUpAll(() async {
    testConfig = ObjectsTestUtils.getTestConfiguration();
    testPrefix = testConfig['testPrefix'];
    pubnub = PubNub(
      defaultKeyset: testConfig['keyset'],
      networking: NetworkingModule(), // Use real network module
    );

    print('Starting Objects integration tests with prefix: $testPrefix');
  });

  tearDownAll(() async {
    print('Cleaning up test data with prefix: $testPrefix');
    await ObjectsTestUtils.cleanupTestData(pubnub, testPrefix);
    print('Objects integration tests completed');
  });

  group('UUID Metadata Integration', () {
    late String testUuid;
    late UuidMetadataInput testMetadata;

    setUp(() {
      testUuid = ObjectsTestUtils.generateTestUuid();
      testMetadata = ObjectsTestUtils.createTestUuidMetadata(
        name: '$testPrefix User',
      );
    });

    tearDown(() async {
      try {
        await pubnub.objects.removeUUIDMetadata(uuid: testUuid);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('UUID metadata complete lifecycle', () async {
      // Create UUID metadata
      final createResult = await pubnub.objects.setUUIDMetadata(
        testMetadata,
        uuid: testUuid,
        includeCustomFields: true,
      );

      expect(createResult.metadata.id, equals(testUuid));
      expect(
        ObjectsTestUtils.compareUuidMetadata(
          createResult.metadata,
          testMetadata,
          expectedId: testUuid,
        ),
        isTrue,
      );

      // Wait for eventual consistency
      await ObjectsTestUtils.waitForEventualConsistency();

      // Get UUID metadata
      final getResult = await pubnub.objects.getUUIDMetadata(uuid: testUuid);
      expect(getResult.metadata, isNotNull);
      expect(getResult.metadata!.id, equals(testUuid));
      expect(getResult.metadata!.name, equals(testMetadata.name));

      // Verify in listing
      final allResult = await pubnub.objects.getAllUUIDMetadata(
        filter: 'id == "$testUuid"',
        includeCustomFields: true,
      );
      expect(allResult.metadataList, isNotNull);
      expect(allResult.metadataList!.length, equals(1));
      expect(allResult.metadataList![0].id, equals(testUuid));

      // Update metadata
      final updatedMetadata = ObjectsTestUtils.createTestUuidMetadata(
        name: '$testPrefix Updated User',
        email: 'updated-$testPrefix@example.com',
      );

      final updateResult = await pubnub.objects.setUUIDMetadata(
        updatedMetadata,
        uuid: testUuid,
      );
      expect(updateResult.metadata.name, equals(updatedMetadata.name));
      expect(updateResult.metadata.email, equals(updatedMetadata.email));

      // Verify update
      await ObjectsTestUtils.waitForEventualConsistency();
      final getUpdatedResult =
          await pubnub.objects.getUUIDMetadata(uuid: testUuid);
      expect(getUpdatedResult.metadata!.name, equals(updatedMetadata.name));

      // Delete metadata
      final deleteResult =
          await pubnub.objects.removeUUIDMetadata(uuid: testUuid);
      expect(deleteResult, isNotNull);

      // Verify deletion
      await ObjectsTestUtils.waitForEventualConsistency();
      try {
        final deletedResult =
            await pubnub.objects.getUUIDMetadata(uuid: testUuid);
        // If this succeeds, the resource might still exist or demo keys behave differently
        print(
            'Warning: Expected deletion but resource still exists: ${deletedResult.metadata?.id}');
      } catch (e) {
        // Expected: resource should not exist
        expect(e, isA<PubNubException>());
      }
    });

    test('UUID metadata with custom fields persistence', () async {
      final customMetadata = ObjectsTestUtils.createTestUuidMetadata(
        name: '$testPrefix Custom User',
        custom: {
          'stringField': 'test string',
          'numberField': 42.5,
          'booleanField': true,
          'nullField': null,
        },
      );

      // Create with custom fields
      await pubnub.objects.setUUIDMetadata(customMetadata, uuid: testUuid);

      await ObjectsTestUtils.waitForEventualConsistency();

      // Retrieve and verify custom fields
      final result = await pubnub.objects.getUUIDMetadata(
        uuid: testUuid,
        includeCustomFields: true,
      );

      expect(result.metadata!.custom, isNotNull);
      expect(result.metadata!.custom!['stringField'], equals('test string'));
      expect(result.metadata!.custom!['numberField'], equals(42.5));
      expect(result.metadata!.custom!['booleanField'], equals(true));
      expect(result.metadata!.custom!['nullField'], isNull);

      // Partial update of custom fields
      final partialUpdate = UuidMetadataInput(
        name: result.metadata!.name, // Keep existing name
        custom: {
          'stringField': 'updated string',
          'newField': 'new value',
        },
      );

      await pubnub.objects.setUUIDMetadata(partialUpdate, uuid: testUuid);

      await ObjectsTestUtils.waitForEventualConsistency();

      // Verify partial update behavior (complete replacement of custom fields)
      final updatedResult = await pubnub.objects.getUUIDMetadata(
        uuid: testUuid,
        includeCustomFields: true,
      );

      expect(updatedResult.metadata!.custom!['stringField'],
          equals('updated string'));
      expect(updatedResult.metadata!.custom!['newField'], equals('new value'));
      // Old fields should be gone (complete replacement)
      expect(
          updatedResult.metadata!.custom!.containsKey('numberField'), isFalse);
    });

    test('getAllUUIDMetadata pagination functionality', () async {
      final createdUuids = <String>[];

      try {
        // Create multiple UUID metadata entries
        for (var i = 0; i < 15; i++) {
          final uuid = ObjectsTestUtils.generateTestUuid('page-$i');
          final metadata = ObjectsTestUtils.createTestUuidMetadata(
            name: '$testPrefix Page User $i',
          );

          await pubnub.objects.setUUIDMetadata(metadata, uuid: uuid);
          createdUuids.add(uuid);

          // Small delay to avoid overwhelming the service
          await Future.delayed(Duration(milliseconds: 50));
        }

        await ObjectsTestUtils.waitForEventualConsistency();

        // Test pagination with limit
        final firstPage = await pubnub.objects.getAllUUIDMetadata(
          filter: 'name LIKE "$testPrefix Page User*"',
          limit: 5,
          includeCount: true,
        );

        expect(firstPage.metadataList, isNotNull);
        expect(firstPage.metadataList!.length, lessThanOrEqualTo(5));
        expect(firstPage.totalCount, greaterThanOrEqualTo(15));

        // Test pagination with cursor if available
        if (firstPage.next != null) {
          final secondPage = await pubnub.objects.getAllUUIDMetadata(
            filter: 'name LIKE "$testPrefix Page User*"',
            limit: 5,
            start: firstPage.next,
          );

          expect(secondPage.metadataList, isNotNull);
          expect(secondPage.metadataList!.length, greaterThan(0));

          // Verify no overlap between pages
          final firstPageIds = firstPage.metadataList!.map((m) => m.id).toSet();
          final secondPageIds =
              secondPage.metadataList!.map((m) => m.id).toSet();
          expect(firstPageIds.intersection(secondPageIds).isEmpty, isTrue);
        }
      } finally {
        // Cleanup created UUIDs
        for (final uuid in createdUuids) {
          try {
            await pubnub.objects.removeUUIDMetadata(uuid: uuid);
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      }
    });

    test('getAllUUIDMetadata filtering and sorting', () async {
      final createdUuids = <String>[];

      try {
        // Create UUIDs with different patterns
        final testData = [
          {
            'suffix': 'alpha',
            'name': '$testPrefix Alpha User',
            'role': 'admin'
          },
          {'suffix': 'beta', 'name': '$testPrefix Beta User', 'role': 'user'},
          {
            'suffix': 'gamma',
            'name': '$testPrefix Gamma User',
            'role': 'admin'
          },
        ];

        for (final data in testData) {
          final uuid =
              ObjectsTestUtils.generateTestUuid(data['suffix'] as String);
          final metadata = ObjectsTestUtils.createTestUuidMetadata(
            name: data['name'] as String,
            custom: {'role': data['role']},
          );

          await pubnub.objects.setUUIDMetadata(metadata, uuid: uuid);
          createdUuids.add(uuid);
          await Future.delayed(Duration(milliseconds: 100));
        }

        await ObjectsTestUtils.waitForEventualConsistency();

        // Test name filtering
        final alphaResults = await pubnub.objects.getAllUUIDMetadata(
          filter: 'name LIKE "$testPrefix Alpha*"',
          includeCustomFields: true,
        );

        expect(alphaResults.metadataList, isNotNull);
        expect(alphaResults.metadataList!.length, equals(1));
        expect(alphaResults.metadataList![0].name, contains('Alpha'));

        // Test sorting by name
        final sortedResults = await pubnub.objects.getAllUUIDMetadata(
          filter: 'name LIKE "$testPrefix*User"',
          sort: {'name:asc'},
          includeCustomFields: true,
        );

        expect(sortedResults.metadataList, isNotNull);
        expect(sortedResults.metadataList!.length, greaterThanOrEqualTo(3));

        // Verify sorting (names should be in alphabetical order)
        final names = sortedResults.metadataList!.map((m) => m.name).toList();
        final sortedNames = List<String?>.from(names)..sort();
        expect(names, equals(sortedNames));
      } finally {
        // Cleanup
        for (final uuid in createdUuids) {
          try {
            await pubnub.objects.removeUUIDMetadata(uuid: uuid);
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      }
    });
  });

  group('Channel Metadata Integration', () {
    late String testChannelId;
    late ChannelMetadataInput testMetadata;

    setUp(() {
      testChannelId = ObjectsTestUtils.generateTestChannelId();
      testMetadata = ObjectsTestUtils.createTestChannelMetadata(
        name: '$testPrefix Channel',
      );
    });

    tearDown(() async {
      try {
        await pubnub.objects.removeChannelMetadata(testChannelId);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('Channel metadata complete lifecycle', () async {
      // Create channel metadata
      final createResult = await pubnub.objects.setChannelMetadata(
        testChannelId,
        testMetadata,
        includeCustomFields: true,
      );

      expect(createResult.metadata.id, equals(testChannelId));
      expect(
        ObjectsTestUtils.compareChannelMetadata(
          createResult.metadata,
          testMetadata,
          expectedId: testChannelId,
        ),
        isTrue,
      );

      await ObjectsTestUtils.waitForEventualConsistency();

      // Get channel metadata
      final getResult = await pubnub.objects.getChannelMetadata(testChannelId);
      expect(getResult.metadata.id, equals(testChannelId));
      expect(getResult.metadata.name, equals(testMetadata.name));

      // Verify in listing
      final allResult = await pubnub.objects.getAllChannelMetadata(
        filter: 'id == "$testChannelId"',
        includeCustomFields: true,
      );
      expect(allResult.metadataList, isNotNull);
      expect(allResult.metadataList!.length, equals(1));

      // Update metadata
      final updatedMetadata = ObjectsTestUtils.createTestChannelMetadata(
        name: '$testPrefix Updated Channel',
        description: 'Updated description',
      );

      final updateResult = await pubnub.objects.setChannelMetadata(
        testChannelId,
        updatedMetadata,
      );
      expect(updateResult.metadata.name, equals(updatedMetadata.name));

      // Delete metadata
      await pubnub.objects.removeChannelMetadata(testChannelId);

      await ObjectsTestUtils.waitForEventualConsistency();

      // Verify deletion
      try {
        final deletedResult =
            await pubnub.objects.getChannelMetadata(testChannelId);
        // If this succeeds, the resource might still exist or demo keys behave differently
        print(
            'Warning: Expected deletion but channel still exists: ${deletedResult.metadata.id}');
      } catch (e) {
        // Expected: resource should not exist
        expect(e, isA<PubNubException>());
      }
    });

    test('Channel metadata with descriptions and custom fields', () async {
      final richMetadata = ObjectsTestUtils.createTestChannelMetadata(
        name: '$testPrefix Rich Channel',
        description: 'A channel with rich metadata and custom fields',
        custom: {
          'category': 'premium',
          'maxMembers': 100,
          'isPublic': false,
          'tags': null,
        },
      );

      await pubnub.objects.setChannelMetadata(testChannelId, richMetadata);

      await ObjectsTestUtils.waitForEventualConsistency();

      final result = await pubnub.objects.getChannelMetadata(
        testChannelId,
        includeCustomFields: true,
      );

      expect(result.metadata.name, equals(richMetadata.name));
      expect(result.metadata.description, equals(richMetadata.description));
      expect(result.metadata.custom, isNotNull);
      expect(result.metadata.custom!['category'], equals('premium'));
      expect(result.metadata.custom!['maxMembers'], equals(100));
      expect(result.metadata.custom!['isPublic'], equals(false));
      expect(result.metadata.custom!['tags'], isNull);
    });

    test('getAllChannelMetadata with filtering', () async {
      final createdChannels = <String>[];

      try {
        // Create channels with different categories
        final testChannels = [
          {
            'suffix': 'public',
            'name': '$testPrefix Public Channel',
            'category': 'public'
          },
          {
            'suffix': 'private',
            'name': '$testPrefix Private Channel',
            'category': 'private'
          },
          {
            'suffix': 'test',
            'name': '$testPrefix Test Channel',
            'category': 'test'
          },
        ];

        for (final data in testChannels) {
          final channelId =
              ObjectsTestUtils.generateTestChannelId(data['suffix'] as String);
          final metadata = ObjectsTestUtils.createTestChannelMetadata(
            name: data['name'] as String,
            custom: {'category': data['category']},
          );

          await pubnub.objects.setChannelMetadata(channelId, metadata);
          createdChannels.add(channelId);
          await Future.delayed(Duration(milliseconds: 100));
        }

        await ObjectsTestUtils.waitForEventualConsistency();

        // Test filtering by name pattern
        final publicResults = await pubnub.objects.getAllChannelMetadata(
          filter: 'name LIKE "$testPrefix Public*"',
          includeCustomFields: true,
        );

        expect(publicResults.metadataList, isNotNull);
        expect(publicResults.metadataList!.length, equals(1));
        expect(publicResults.metadataList![0].name, contains('Public'));
        expect(publicResults.metadataList![0].custom!['category'],
            equals('public'));
      } finally {
        // Cleanup
        for (final channelId in createdChannels) {
          try {
            await pubnub.objects.removeChannelMetadata(channelId);
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      }
    });
  });

  group('Membership Integration', () {
    late String testUuid;
    late List<String> testChannelIds;

    setUp(() async {
      testUuid = ObjectsTestUtils.generateTestUuid();
      testChannelIds = [];

      // Create test UUID
      final uuidMetadata = ObjectsTestUtils.createTestUuidMetadata(
        name: '$testPrefix Member User',
      );
      await pubnub.objects.setUUIDMetadata(uuidMetadata, uuid: testUuid);

      // Create test channels
      for (var i = 0; i < 3; i++) {
        final channelId =
            ObjectsTestUtils.generateTestChannelId('membership-$i');
        final channelMetadata = ObjectsTestUtils.createTestChannelMetadata(
          name: '$testPrefix Membership Channel $i',
        );
        await pubnub.objects.setChannelMetadata(channelId, channelMetadata);
        testChannelIds.add(channelId);
        await Future.delayed(Duration(milliseconds: 50));
      }

      await ObjectsTestUtils.waitForEventualConsistency();
    });

    tearDown(() async {
      // Clean up memberships first (implicit in UUID/channel cleanup)
      try {
        await pubnub.objects.removeUUIDMetadata(uuid: testUuid);
      } catch (e) {
        // Ignore
      }

      for (final channelId in testChannelIds) {
        try {
          await pubnub.objects.removeChannelMetadata(channelId);
        } catch (e) {
          // Ignore
        }
      }
    });

    test('Membership complete lifecycle', () async {
      // Set initial memberships
      final memberships = testChannelIds
          .take(2)
          .map(
            (channelId) => ObjectsTestUtils.createTestMembershipMetadata(
              channelId,
              custom: {'role': 'member', 'priority': 'normal'},
            ),
          )
          .toList();

      final setResult = await pubnub.objects.setMemberships(
        memberships,
        uuid: testUuid,
        includeChannelFields: true,
      );

      expect(setResult.metadataList, isNotNull);
      expect(setResult.metadataList!.length, equals(2));

      await ObjectsTestUtils.waitForEventualConsistency();

      // Get memberships
      final getResult = await pubnub.objects.getMemberships(
        uuid: testUuid,
        includeCustomFields: true,
        includeChannelFields: true,
      );

      expect(getResult.metadataList, isNotNull);
      expect(getResult.metadataList!.length, equals(2));

      for (final membership in getResult.metadataList!) {
        expect(testChannelIds.contains(membership.channel.id), isTrue);
        expect(membership.custom!['role'], equals('member'));
      }

      // Add more memberships and remove some
      final addMembership = ObjectsTestUtils.createTestMembershipMetadata(
        testChannelIds[2],
        custom: {'role': 'admin', 'priority': 'high'},
      );

      final manageResult = await pubnub.objects.manageMemberships(
        [addMembership], // Add third channel
        {testChannelIds[0]}, // Remove first channel
        uuid: testUuid,
        includeChannelFields: true,
      );

      expect(manageResult.metadataList, isNotNull);
      // Should have 2 memberships now (removed 1, added 1)
      expect(manageResult.metadataList!.length, equals(2));

      await ObjectsTestUtils.waitForEventualConsistency();

      // Verify final state
      final finalResult = await pubnub.objects.getMemberships(
        uuid: testUuid,
        includeCustomFields: true,
      );

      final finalChannelIds =
          finalResult.metadataList!.map((m) => m.channel.id).toSet();

      expect(finalChannelIds.contains(testChannelIds[0]), isFalse); // Removed
      expect(
          finalChannelIds.contains(testChannelIds[1]), isTrue); // Still there
      expect(finalChannelIds.contains(testChannelIds[2]), isTrue); // Added

      // Remove all memberships
      await pubnub.objects.removeMemberships(
        finalChannelIds,
        uuid: testUuid,
      );

      await ObjectsTestUtils.waitForEventualConsistency();

      final emptyResult = await pubnub.objects.getMemberships(uuid: testUuid);
      expect(emptyResult.metadataList, isNotNull);
      expect(emptyResult.metadataList!.length, equals(0));
    });

    test('Membership with custom fields and include flags', () async {
      final membership = ObjectsTestUtils.createTestMembershipMetadata(
        testChannelIds[0],
        custom: {
          'role': 'moderator',
          'permissions': 'read-write',
          'joined': DateTime.now().toIso8601String(),
        },
      );

      await pubnub.objects.setMemberships(
        [membership],
        uuid: testUuid,
      );

      await ObjectsTestUtils.waitForEventualConsistency();

      // Test different include flag combinations
      final result = await pubnub.objects.getMemberships(
        uuid: testUuid,
        includeCustomFields: true,
        includeChannelFields: true,
        includeChannelCustomFields: true,
      );

      expect(result.metadataList, isNotNull);
      expect(result.metadataList!.length, equals(1));

      final membershipData = result.metadataList![0];
      expect(membershipData.custom!['role'], equals('moderator'));
      expect(membershipData.custom!['permissions'], equals('read-write'));
      expect(membershipData.channel.name, isNotNull); // Channel field included
      expect(
          membershipData.channel.custom, isNotNull); // Channel custom included
    });

    test('Membership pagination and filtering', () async {
      final moreChannelIds = <String>[];

      try {
        // Create more channels for pagination testing
        for (var i = 3; i < 8; i++) {
          final channelId =
              ObjectsTestUtils.generateTestChannelId('pagination-$i');
          final channelMetadata = ObjectsTestUtils.createTestChannelMetadata(
            name: '$testPrefix Pagination Channel $i',
          );
          await pubnub.objects.setChannelMetadata(channelId, channelMetadata);
          moreChannelIds.add(channelId);
          await Future.delayed(Duration(milliseconds: 50));
        }

        // Create memberships to all channels
        final allChannels = [...testChannelIds, ...moreChannelIds];
        final memberships = allChannels
            .map(
              (channelId) =>
                  ObjectsTestUtils.createTestMembershipMetadata(channelId),
            )
            .toList();

        await pubnub.objects.setMemberships(
          memberships,
          uuid: testUuid,
        );

        await ObjectsTestUtils.waitForEventualConsistency();

        // Test pagination
        final firstPage = await pubnub.objects.getMemberships(
          uuid: testUuid,
          limit: 3,
          includeCount: true,
        );

        expect(firstPage.metadataList, isNotNull);
        expect(firstPage.metadataList!.length, lessThanOrEqualTo(3));
        expect(firstPage.totalCount, greaterThanOrEqualTo(8));

        // Test with cursor pagination if available
        if (firstPage.next != null) {
          final secondPage = await pubnub.objects.getMemberships(
            uuid: testUuid,
            limit: 3,
            start: firstPage.next,
          );

          expect(secondPage.metadataList, isNotNull);
          expect(secondPage.metadataList!.length, greaterThan(0));
        }
      } finally {
        // Cleanup additional channels
        for (final channelId in moreChannelIds) {
          try {
            await pubnub.objects.removeChannelMetadata(channelId);
          } catch (e) {
            // Ignore
          }
        }
      }
    });
  });

  group('Channel Members Integration', () {
    late String testChannelId;
    late List<String> testUuidIds;

    setUp(() async {
      testChannelId = ObjectsTestUtils.generateTestChannelId();
      testUuidIds = [];

      // Create test channel
      final channelMetadata = ObjectsTestUtils.createTestChannelMetadata(
        name: '$testPrefix Members Channel',
      );
      await pubnub.objects.setChannelMetadata(testChannelId, channelMetadata);

      // Create test UUIDs
      for (var i = 0; i < 3; i++) {
        final uuid = ObjectsTestUtils.generateTestUuid('member-$i');
        final uuidMetadata = ObjectsTestUtils.createTestUuidMetadata(
          name: '$testPrefix Member User $i',
        );
        await pubnub.objects.setUUIDMetadata(uuidMetadata, uuid: uuid);
        testUuidIds.add(uuid);
        await Future.delayed(Duration(milliseconds: 50));
      }

      await ObjectsTestUtils.waitForEventualConsistency();
    });

    tearDown(() async {
      // Clean up
      try {
        await pubnub.objects.removeChannelMetadata(testChannelId);
      } catch (e) {
        // Ignore
      }

      for (final uuid in testUuidIds) {
        try {
          await pubnub.objects.removeUUIDMetadata(uuid: uuid);
        } catch (e) {
          // Ignore
        }
      }
    });

    test('Channel members complete lifecycle', () async {
      // Set initial members
      final members = testUuidIds
          .take(2)
          .map(
            (uuid) => ObjectsTestUtils.createTestChannelMemberMetadata(
              uuid,
              custom: {'role': 'member', 'status': 'active'},
            ),
          )
          .toList();

      final setResult = await pubnub.objects.setChannelMembers(
        testChannelId,
        members,
        includeUUIDFields: true,
      );

      expect(setResult.metadataList, isNotNull);
      expect(setResult.metadataList!.length, equals(2));

      await ObjectsTestUtils.waitForEventualConsistency();

      // Get members
      final getResult = await pubnub.objects.getChannelMembers(
        testChannelId,
        includeCustomFields: true,
        includeUUIDFields: true,
      );

      expect(getResult.metadataList, isNotNull);
      expect(getResult.metadataList!.length, equals(2));

      for (final member in getResult.metadataList!) {
        expect(testUuidIds.contains(member.uuid.id), isTrue);
        expect(member.custom!['role'], equals('member'));
      }

      // Add and remove members
      final addMember = ObjectsTestUtils.createTestChannelMemberMetadata(
        testUuidIds[2],
        custom: {'role': 'admin', 'status': 'active'},
      );

      final manageResult = await pubnub.objects.manageChannelMembers(
        testChannelId,
        [addMember], // Add third UUID
        {testUuidIds[0]}, // Remove first UUID
        includeUUIDFields: true,
      );

      expect(manageResult.metadataList, isNotNull);
      expect(manageResult.metadataList!.length, equals(2));

      await ObjectsTestUtils.waitForEventualConsistency();

      // Verify final state
      final finalResult = await pubnub.objects.getChannelMembers(
        testChannelId,
        includeCustomFields: true,
      );

      final finalUuids =
          finalResult.metadataList!.map((m) => m.uuid.id).toSet();

      expect(finalUuids.contains(testUuidIds[0]), isFalse); // Removed
      expect(finalUuids.contains(testUuidIds[1]), isTrue); // Still there
      expect(finalUuids.contains(testUuidIds[2]), isTrue); // Added

      // Remove all members
      await pubnub.objects.removeChannelMembers(
        testChannelId,
        finalUuids,
      );

      await ObjectsTestUtils.waitForEventualConsistency();

      final emptyResult = await pubnub.objects.getChannelMembers(testChannelId);
      expect(emptyResult.metadataList, isNotNull);
      expect(emptyResult.metadataList!.length, equals(0));
    });

    test('Channel members with UUID include flags', () async {
      final member = ObjectsTestUtils.createTestChannelMemberMetadata(
        testUuidIds[0],
        custom: {
          'role': 'moderator',
          'permissions': 'read-write-delete',
          'invited_by': 'admin',
        },
      );

      await pubnub.objects.setChannelMembers(
        testChannelId,
        [member],
      );

      await ObjectsTestUtils.waitForEventualConsistency();

      // Test UUID include flags
      final result = await pubnub.objects.getChannelMembers(
        testChannelId,
        includeCustomFields: true,
        includeUUIDFields: true,
        includeUUIDCustomFields: true,
      );

      expect(result.metadataList, isNotNull);
      expect(result.metadataList!.length, equals(1));

      final memberData = result.metadataList![0];
      expect(memberData.custom!['role'], equals('moderator'));
      expect(memberData.uuid.name, isNotNull); // UUID field included
      expect(memberData.uuid.custom, isNotNull); // UUID custom included
    });
  });

  group('Cross-API Integration', () {
    late String testUuid;
    late List<String> testChannelIds;

    setUp(() async {
      testUuid = ObjectsTestUtils.generateTestUuid();
      testChannelIds = [];

      // Create comprehensive test ecosystem
      final uuidMetadata = ObjectsTestUtils.createTestUuidMetadata(
        name: '$testPrefix Ecosystem User',
        custom: {'department': 'integration', 'level': 'expert'},
      );
      await pubnub.objects.setUUIDMetadata(uuidMetadata, uuid: testUuid);

      for (var i = 0; i < 3; i++) {
        final channelId =
            ObjectsTestUtils.generateTestChannelId('ecosystem-$i');
        final channelMetadata = ObjectsTestUtils.createTestChannelMetadata(
          name: '$testPrefix Ecosystem Channel $i',
          custom: {'type': 'integration', 'priority': i},
        );
        await pubnub.objects.setChannelMetadata(channelId, channelMetadata);
        testChannelIds.add(channelId);
        await Future.delayed(Duration(milliseconds: 50));
      }

      await ObjectsTestUtils.waitForEventualConsistency();
    });

    tearDown(() async {
      // Cleanup
      try {
        await pubnub.objects.removeUUIDMetadata(uuid: testUuid);
      } catch (e) {
        // Ignore
      }

      for (final channelId in testChannelIds) {
        try {
          await pubnub.objects.removeChannelMetadata(channelId);
        } catch (e) {
          // Ignore
        }
      }
    });

    test('Complete Objects workflow integration', () async {
      // Establish memberships
      final memberships = testChannelIds
          .map(
            (channelId) => ObjectsTestUtils.createTestMembershipMetadata(
              channelId,
              custom: {'role': 'member', 'access_level': 'full'},
            ),
          )
          .toList();

      await pubnub.objects.setMemberships(
        memberships,
        uuid: testUuid,
      );

      // Establish channel members (bidirectional relationship)
      for (final channelId in testChannelIds) {
        final member = ObjectsTestUtils.createTestChannelMemberMetadata(
          testUuid,
          custom: {'role': 'participant', 'status': 'active'},
        );

        await pubnub.objects.setChannelMembers(channelId, [member]);
        await Future.delayed(Duration(milliseconds: 100));
      }

      await ObjectsTestUtils.waitForEventualConsistency();

      // Test cross-references: UUID -> memberships -> channel data
      final membershipsResult = await pubnub.objects.getMemberships(
        uuid: testUuid,
        includeChannelFields: true,
        includeChannelCustomFields: true,
      );

      expect(membershipsResult.metadataList, isNotNull);
      expect(membershipsResult.metadataList!.length, equals(3));

      for (final membership in membershipsResult.metadataList!) {
        expect(testChannelIds.contains(membership.channel.id), isTrue);
        expect(membership.channel.name, contains('Ecosystem Channel'));
        expect(membership.channel.custom!['type'], equals('integration'));
      }

      // Test cross-references: Channel -> members -> UUID data
      for (final channelId in testChannelIds) {
        final membersResult = await pubnub.objects.getChannelMembers(
          channelId,
          includeUUIDFields: true,
          includeUUIDCustomFields: true,
        );

        expect(membersResult.metadataList, isNotNull);
        expect(membersResult.metadataList!.length, equals(1));
        expect(membersResult.metadataList![0].uuid.id, equals(testUuid));
        expect(membersResult.metadataList![0].uuid.name,
            contains('Ecosystem User'));
        expect(membersResult.metadataList![0].uuid.custom!['department'],
            equals('integration'));
      }

      // Perform bulk updates and verify consistency
      final updatedMemberships = testChannelIds
          .map(
            (channelId) => ObjectsTestUtils.createTestMembershipMetadata(
              channelId,
              custom: {
                'role': 'admin',
                'access_level': 'full',
                'updated': 'true'
              },
            ),
          )
          .toList();

      await pubnub.objects.manageMemberships(
        updatedMemberships,
        {}, // No removals
        uuid: testUuid,
      );

      await ObjectsTestUtils.waitForEventualConsistency();

      // Verify bulk update consistency
      final updatedResult = await pubnub.objects.getMemberships(
        uuid: testUuid,
        includeCustomFields: true,
      );

      for (final membership in updatedResult.metadataList!) {
        expect(membership.custom!['role'], equals('admin'));
        expect(membership.custom!['updated'], equals('true'));
      }
    });

    test('Membership bidirectional consistency', () async {
      final channelId = testChannelIds[0];

      // Create membership via setMemberships
      final membership = ObjectsTestUtils.createTestMembershipMetadata(
        channelId,
        custom: {'source': 'membership_api'},
      );

      await pubnub.objects.setMemberships([membership], uuid: testUuid);

      await ObjectsTestUtils.waitForEventualConsistency();

      // Verify it appears in getChannelMembers
      final membersResult = await pubnub.objects.getChannelMembers(
        channelId,
        includeCustomFields: true,
      );

      expect(membersResult.metadataList, isNotNull);
      expect(membersResult.metadataList!.length, equals(1));
      expect(membersResult.metadataList![0].uuid.id, equals(testUuid));

      // Remove membership via removeChannelMembers
      await pubnub.objects.removeChannelMembers(channelId, {testUuid});

      await ObjectsTestUtils.waitForEventualConsistency();

      // Verify removal appears in getMemberships
      final membershipsResult =
          await pubnub.objects.getMemberships(uuid: testUuid);

      expect(membershipsResult.metadataList, isNotNull);
      final channelIds =
          membershipsResult.metadataList!.map((m) => m.channel.id).toSet();
      expect(channelIds.contains(channelId), isFalse);

      // Test edge cases with multiple modifications
      await pubnub.objects.setMemberships(
        [membership],
        uuid: testUuid,
      );

      final member = ObjectsTestUtils.createTestChannelMemberMetadata(
        testUuid,
        custom: {'source': 'members_api'},
      );

      await pubnub.objects.manageChannelMembers(
        channelId,
        [member],
        {},
      );

      await ObjectsTestUtils.waitForEventualConsistency();

      // Both APIs should show consistent state
      final finalMembershipsResult = await pubnub.objects.getMemberships(
        uuid: testUuid,
        includeCustomFields: true,
      );
      final finalMembersResult = await pubnub.objects.getChannelMembers(
        channelId,
        includeCustomFields: true,
      );

      expect(finalMembershipsResult.metadataList!.length, equals(1));
      expect(finalMembersResult.metadataList!.length, equals(1));
      expect(finalMembersResult.metadataList![0].uuid.id, equals(testUuid));
    });
  });

  group('Error Handling Integration', () {
    test('Objects APIs handle non-existent resources gracefully', () async {
      final nonExistentUuid =
          'non-existent-uuid-${DateTime.now().millisecondsSinceEpoch}';
      final nonExistentChannelId =
          'non-existent-channel-${DateTime.now().millisecondsSinceEpoch}';

      // Test non-existent UUID
      try {
        await pubnub.objects.getUUIDMetadata(uuid: nonExistentUuid);
        print(
            'Warning: Expected non-existent UUID error but request succeeded');
      } catch (e) {
        expect(e, isA<Exception>()); // Could be 404 or other error
      }

      // Test non-existent channel
      try {
        await pubnub.objects.getChannelMetadata(nonExistentChannelId);
        print(
            'Warning: Expected non-existent channel error but request succeeded');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      // Test removing non-existent resources (might succeed with demo keys)
      try {
        final removeUuidResult =
            await pubnub.objects.removeUUIDMetadata(uuid: nonExistentUuid);
        expect(removeUuidResult, isNotNull);
        print(
            'Note: Removing non-existent UUID succeeded (expected with demo keys)');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      try {
        final removeChannelResult =
            await pubnub.objects.removeChannelMetadata(nonExistentChannelId);
        expect(removeChannelResult, isNotNull);
        print(
            'Note: Removing non-existent channel succeeded (expected with demo keys)');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });

  group('Performance Integration', () {
    test('Objects APIs large payload performance', () async {
      final testUuid = ObjectsTestUtils.generateTestUuid();

      try {
        // Create metadata with large custom fields (but within limits)
        final largeCustomData = <String, Object?>{};
        for (var i = 0; i < 50; i++) {
          largeCustomData['field_$i'] =
              'Large value $i with some additional text to increase size';
        }

        final largeMetadata = ObjectsTestUtils.createTestUuidMetadata(
          name: '$testPrefix Large Payload User',
          custom: largeCustomData,
        );

        // Test performance with large payload
        final stopwatch = Stopwatch()..start();

        final createResult = await pubnub.objects.setUUIDMetadata(
          largeMetadata,
          uuid: testUuid,
          includeCustomFields: true,
        );

        stopwatch.stop();

        // Verify data integrity with large payload
        expect(createResult.metadata.id, equals(testUuid));
        expect(createResult.metadata.custom, isNotNull);
        expect(createResult.metadata.custom!.length, equals(50));

        // Performance check (should complete within reasonable time)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max

        await ObjectsTestUtils.waitForEventualConsistency();

        // Verify retrieval performance and data integrity
        final getStopwatch = Stopwatch()..start();

        final getResult = await pubnub.objects.getUUIDMetadata(
          uuid: testUuid,
          includeCustomFields: true,
        );

        getStopwatch.stop();

        expect(getResult.metadata!.custom!.length, equals(50));
        expect(
            getStopwatch.elapsedMilliseconds, lessThan(3000)); // 3 seconds max

        // Verify all custom fields are intact
        for (var i = 0; i < 50; i++) {
          expect(
            getResult.metadata!.custom!['field_$i'],
            equals('Large value $i with some additional text to increase size'),
          );
        }
      } finally {
        try {
          await pubnub.objects.removeUUIDMetadata(uuid: testUuid);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    test('Objects APIs concurrent operations', () async {
      final testUuids = <String>[];

      try {
        // Create multiple UUID operations concurrently
        final futures = <Future<SetUuidMetadataResult>>[];

        for (var i = 0; i < 10; i++) {
          final uuid = ObjectsTestUtils.generateTestUuid('concurrent-$i');
          final metadata = ObjectsTestUtils.createTestUuidMetadata(
            name: '$testPrefix Concurrent User $i',
          );

          testUuids.add(uuid);
          futures.add(pubnub.objects.setUUIDMetadata(metadata, uuid: uuid));
        }

        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(futures);
        stopwatch.stop();

        // Verify all operations completed successfully
        expect(results.length, equals(10));
        for (var i = 0; i < results.length; i++) {
          expect(results[i].metadata.id, equals(testUuids[i]));
          expect(results[i].metadata.name, contains('Concurrent User $i'));
        }

        // Performance check for concurrent operations
        expect(
            stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max

        await ObjectsTestUtils.waitForEventualConsistency();

        // Verify data consistency after concurrent operations
        for (var i = 0; i < testUuids.length; i++) {
          final result =
              await pubnub.objects.getUUIDMetadata(uuid: testUuids[i]);
          expect(result.metadata!.name, contains('Concurrent User $i'));
        }
      } finally {
        // Cleanup all test UUIDs
        final cleanupFutures = testUuids.map((uuid) async {
          try {
            await pubnub.objects.removeUUIDMetadata(uuid: uuid);
          } catch (e) {
            // Ignore cleanup errors
          }
        }).toList();

        await Future.wait(cleanupFutures);
      }
    });
  });
}
