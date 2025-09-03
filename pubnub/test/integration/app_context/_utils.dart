import 'package:pubnub/pubnub.dart';

/// Utility class for Objects integration tests
class ObjectsTestUtils {
  /// Generates a unique test identifier
  static String generateTestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'test-objects-$timestamp';
  }

  /// Generates a test UUID with unique suffix
  static String generateTestUuid([String? suffix]) {
    final base = generateTestId();
    return suffix != null ? '$base-$suffix' : '$base-uuid';
  }

  /// Generates a test channel ID with unique suffix
  static String generateTestChannelId([String? suffix]) {
    final base = generateTestId();
    return suffix != null ? '$base-$suffix' : '$base-channel';
  }

  /// Creates test UUID metadata input
  static UuidMetadataInput createTestUuidMetadata({
    String? name,
    String? email,
    String? externalId,
    String? profileUrl,
    Map<String, Object?>? custom,
  }) {
    final testId = generateTestId();
    return UuidMetadataInput(
      name: name ?? 'Test User $testId',
      email: email ?? 'test-$testId@example.com',
      externalId: externalId ?? 'ext-$testId',
      profileUrl: profileUrl ?? 'https://example.com/avatar-$testId.jpg',
      custom: custom ??
          {
            'role': 'test',
            'department': 'qa',
            'active': true,
            'priority': 5,
          },
    );
  }

  /// Creates test channel metadata input
  static ChannelMetadataInput createTestChannelMetadata({
    String? name,
    String? description,
    Map<String, Object?>? custom,
  }) {
    final testId = generateTestId();
    return ChannelMetadataInput(
      name: name ?? 'Test Channel $testId',
      description: description ?? 'Test channel description for $testId',
      custom: custom ??
          {
            'category': 'test',
            'type': 'integration-test',
            'priority': 1,
            'public': false,
          },
    );
  }

  /// Creates test membership metadata input
  static MembershipMetadataInput createTestMembershipMetadata(
    String channelId, {
    Map<String, Object?>? custom,
  }) {
    return MembershipMetadataInput(
      channelId,
      custom: custom ??
          {
            'role': 'member',
            'joined': DateTime.now().toIso8601String(),
            'notifications': true,
            'priority': 'normal',
          },
    );
  }

  /// Creates test channel member metadata input
  static ChannelMemberMetadataInput createTestChannelMemberMetadata(
    String uuid, {
    Map<String, Object?>? custom,
  }) {
    return ChannelMemberMetadataInput(
      uuid,
      custom: custom ??
          {
            'role': 'member',
            'invited_by': 'admin',
            'permissions': 'read',
            'status': 'active',
          },
    );
  }

  /// Cleans up test data by removing all metadata with test prefix
  static Future<void> cleanupTestData(
    PubNub pubnub,
    String testPrefix,
  ) async {
    try {
      // Clean up UUID metadata
      final uuidsResult = await pubnub.objects.getAllUUIDMetadata(
        filter: 'name LIKE "$testPrefix*"',
        limit: 100,
      );

      if (uuidsResult.metadataList != null) {
        for (final uuidMetadata in uuidsResult.metadataList!) {
          try {
            await pubnub.objects.removeUUIDMetadata(uuid: uuidMetadata.id);
          } catch (e) {
            // Ignore cleanup errors
            print('Failed to cleanup UUID ${uuidMetadata.id}: $e');
          }
        }
      }

      // Clean up channel metadata
      final channelsResult = await pubnub.objects.getAllChannelMetadata(
        filter: 'name LIKE "$testPrefix*"',
        limit: 100,
      );

      if (channelsResult.metadataList != null) {
        for (final channelMetadata in channelsResult.metadataList!) {
          try {
            await pubnub.objects.removeChannelMetadata(channelMetadata.id);
          } catch (e) {
            // Ignore cleanup errors
            print('Failed to cleanup channel ${channelMetadata.id}: $e');
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
      print('Failed to cleanup test data: $e');
    }
  }

  /// Waits for eventual consistency (used after operations that might need time to propagate)
  static Future<void> waitForEventualConsistency([Duration? delay]) async {
    await Future.delayed(delay ?? Duration(milliseconds: 500));
  }

  /// Creates multiple test UUIDs for bulk operations
  static Future<List<String>> createMultipleTestUuids(
    PubNub pubnub,
    int count, {
    String? namePrefix,
  }) async {
    final uuidIds = <String>[];

    for (var i = 0; i < count; i++) {
      final uuid = generateTestUuid('bulk-$i');
      final metadata = createTestUuidMetadata(
        name: '${namePrefix ?? 'Bulk Test User'} $i',
      );

      await pubnub.objects.setUUIDMetadata(metadata, uuid: uuid);
      uuidIds.add(uuid);

      // Small delay to avoid overwhelming the service
      if (i % 10 == 9) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    return uuidIds;
  }

  /// Creates multiple test channels for bulk operations
  static Future<List<String>> createMultipleTestChannels(
    PubNub pubnub,
    int count, {
    String? namePrefix,
  }) async {
    final channelIds = <String>[];

    for (var i = 0; i < count; i++) {
      final channelId = generateTestChannelId('bulk-$i');
      final metadata = createTestChannelMetadata(
        name: '${namePrefix ?? 'Bulk Test Channel'} $i',
      );

      await pubnub.objects.setChannelMetadata(channelId, metadata);
      channelIds.add(channelId);

      // Small delay to avoid overwhelming the service
      if (i % 10 == 9) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }

    return channelIds;
  }

  /// Verifies that two UUID metadata objects are equivalent
  static bool compareUuidMetadata(
    UuidMetadataDetails actual,
    UuidMetadataInput expected, {
    String? expectedId,
  }) {
    if (expectedId != null && actual.id != expectedId) return false;

    // Compare non-null expected fields with actual fields
    if (expected.name != null && actual.name != expected.name) return false;
    if (expected.email != null && actual.email != expected.email) return false;
    if (expected.externalId != null && actual.externalId != expected.externalId)
      return false;
    if (expected.profileUrl != null && actual.profileUrl != expected.profileUrl)
      return false;

    // Compare custom fields - only check if expected custom fields are provided
    if (expected.custom != null) {
      if (actual.custom == null) return false;

      for (final key in expected.custom!.keys) {
        if (actual.custom![key] != expected.custom![key]) return false;
      }
    }

    return true;
  }

  /// Verifies that two channel metadata objects are equivalent
  static bool compareChannelMetadata(
    ChannelMetadataDetails actual,
    ChannelMetadataInput expected, {
    String? expectedId,
  }) {
    if (expectedId != null && actual.id != expectedId) return false;

    // Compare non-null expected fields with actual fields
    if (expected.name != null && actual.name != expected.name) return false;
    if (expected.description != null &&
        actual.description != expected.description) return false;

    // Compare custom fields - only check if expected custom fields are provided
    if (expected.custom != null) {
      if (actual.custom == null) return false;

      for (final key in expected.custom!.keys) {
        if (actual.custom![key] != expected.custom![key]) return false;
      }
    }

    return true;
  }

  /// Gets a demo keyset for testing (using PubNub demo keys)
  static Keyset getDemoKeyset([String? userId]) {
    return Keyset(
      subscribeKey: 'demo',
      publishKey: 'demo',
      userId: UserId(userId ?? generateTestUuid()),
    );
  }

  /// Creates a test configuration for consistent testing
  static Map<String, dynamic> getTestConfiguration() {
    final testId = generateTestId();
    return {
      'testId': testId,
      'testPrefix': 'int-test-$testId',
      'keyset': getDemoKeyset('test-user-$testId'),
      'limits': {
        'defaultLimit': 50,
        'maxBulkOperations': 25,
        'paginationLimit': 10,
      },
      'delays': {
        'eventualConsistency': Duration(milliseconds: 500),
        'bulkOperationDelay': Duration(milliseconds: 100),
        'retryDelay': Duration(seconds: 1),
      }
    };
  }

  /// Retries an operation with exponential backoff
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    double backoffMultiplier = 2.0,
  }) async {
    var attempts = 0;
    var currentDelay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }

        print('Operation failed (attempt $attempts/$maxRetries): $e');
        print('Retrying in ${currentDelay.inMilliseconds}ms...');

        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds:
              (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw Exception('Should not reach here');
  }
}
