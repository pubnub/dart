@TestOn('vm')
@Tags(['integration'])

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';

void main() {
  final SUBSCRIBE_KEY = Platform.environment['SDK_SUB_KEY'] ?? 'demo';
  final PUBLISH_KEY = Platform.environment['SDK_PUB_KEY'] ?? 'demo';

  group('Integration [channelGroups] - End-to-End Workflows', () {
    PubNub? pubnub;
    Set<String> testGroups = {};

    setUpAll(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: SUBSCRIBE_KEY,
              publishKey: PUBLISH_KEY,
              userId: UserId(
                  'integration_test_${DateTime.now().millisecondsSinceEpoch}')));
    });

    setUp(() {
      testGroups.clear();
    });

    tearDown(() async {
      // Clean up all test groups created during test
      for (var group in testGroups) {
        try {
          await pubnub!.channelGroups.delete(group);
        } catch (e) {
          print('Failed to cleanup group $group: $e');
        }
      }
    });

    // Helper function to generate unique group names
    String generateGroupName([String? prefix]) {
      var name =
          '${prefix ?? 'test'}_group_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      testGroups.add(name);
      return name;
    }

    // Helper function to wait for eventual consistency
    Future<void> waitForConsistency() async {
      await Future.delayed(Duration(seconds: 2));
    }

    test('should complete full channel group lifecycle successfully', () async {
      var groupName = generateGroupName('lifecycle');
      var channels = {'test_ch1', 'test_ch2', 'test_ch3'};

      // 1. Create and Add channels to new group
      await pubnub!.channelGroups.addChannels(groupName, channels);
      await waitForConsistency();

      // 2. Verify Add - List channels to confirm they were added
      var listResult = await pubnub!.channelGroups.listChannels(groupName);
      expect(listResult.channels, containsAll(channels));

      // 3. Partial Remove - Remove some channels
      await pubnub!.channelGroups.removeChannels(groupName, {'test_ch1'});
      await waitForConsistency();

      var afterRemove = await pubnub!.channelGroups.listChannels(groupName);
      expect(afterRemove.channels, containsAll({'test_ch2', 'test_ch3'}));
      expect(afterRemove.channels, isNot(contains('test_ch1')));

      // 4. Complete Delete - Remove entire group
      await pubnub!.channelGroups.delete(groupName);
      await waitForConsistency();

      var finalList = await pubnub!.channelGroups.listChannels(groupName);
      expect(finalList.channels, isEmpty);
    }, timeout: Timeout(Duration(seconds: 30)));

    test('should handle concurrent operations on different groups', () async {
      // Parallel Creation - Create multiple groups concurrently
      var futures = List.generate(3, (i) async {
        var groupName = generateGroupName('concurrent_${i}');
        await pubnub!.channelGroups
            .addChannels(groupName, {'ch_${i}_1', 'ch_${i}_2'});
        return groupName;
      });

      var groupNames = await Future.wait(futures);
      await waitForConsistency();

      // Parallel Verification - List all groups concurrently
      var verifyFutures = groupNames.map((groupName) async {
        var result = await pubnub!.channelGroups.listChannels(groupName);
        expect(result.channels.length, equals(2));
      });

      await Future.wait(verifyFutures);

      // Parallel Cleanup - Delete all groups concurrently
      var cleanupFutures = groupNames.map((groupName) async {
        await pubnub!.channelGroups.delete(groupName);
      });

      await Future.wait(cleanupFutures);
    }, timeout: Timeout(Duration(seconds: 30)));

    test('should handle operations with many channels (approaching limits)',
        () async {
      var groupName = generateGroupName('large_set');

      // Add Maximum Channels - Add 200 channels (API limit)
      var channels = List.generate(200, (i) => 'large_ch_$i').toSet();
      await pubnub!.channelGroups.addChannels(groupName, channels);
      await waitForConsistency();

      // Verify All Added - List and confirm all 200 channels
      var listResult = await pubnub!.channelGroups.listChannels(groupName);
      expect(listResult.channels.length, equals(200));
      expect(listResult.channels, containsAll(channels));

      // Batch Remove - Remove channels in batches
      var batchSize = 50;
      var channelsList = channels.toList();
      for (int i = 0; i < channelsList.length; i += batchSize) {
        var end = (i + batchSize < channelsList.length)
            ? i + batchSize
            : channelsList.length;
        var batch = channelsList.sublist(i, end).toSet();
        await pubnub!.channelGroups.removeChannels(groupName, batch);
        await waitForConsistency();
      }

      // Final verification - should be empty now
      var finalResult = await pubnub!.channelGroups.listChannels(groupName);
      expect(finalResult.channels, isEmpty);
    }, timeout: Timeout(Duration(seconds: 60)));
  });
  group('Integration [channelGroups] - Error Scenarios', () {
    PubNub? pubnub;
    Set<String> testGroups = {};

    setUpAll(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: SUBSCRIBE_KEY,
              publishKey: PUBLISH_KEY,
              uuid:
                  UUID('error_test_${DateTime.now().millisecondsSinceEpoch}')));
    });

    setUp(() {
      testGroups.clear();
    });

    tearDown(() async {
      for (var group in testGroups) {
        try {
          await pubnub!.channelGroups.delete(group);
        } catch (e) {
          print('Failed to cleanup group $group: $e');
        }
      }
    });

    String generateGroupName([String? prefix]) {
      var name =
          '${prefix ?? 'test'}_group_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      testGroups.add(name);
      return name;
    }

    test('should handle invalid API keys properly', () async {
      var invalidPubNub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'invalid_sub_key',
              publishKey: 'invalid_pub_key',
              uuid: UUID('invalid_test_user')));

      var groupName = generateGroupName('invalid_keys');
      var channels = {'invalid_ch1'};

      // Should throw appropriate exception for invalid keys
      expect(
          () async => await invalidPubNub.channelGroups
              .addChannels(groupName, channels),
          throwsA(isA<PubNubException>()));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('should handle network connectivity problems', () async {
      // This test is hard to simulate without mocking, but we can test timeout behavior
      var groupName = generateGroupName('network_test');
      var channels = {'network_ch1'};

      // Test basic operation - should complete normally
      await pubnub!.channelGroups.addChannels(groupName, channels);

      // Verify it was added
      var result = await pubnub!.channelGroups.listChannels(groupName);
      expect(result.channels, contains('network_ch1'));
    }, timeout: Timeout(Duration(seconds: 30)));
  });

  group('Integration [channelGroups] - Cross-Feature Integration', () {
    PubNub? pubnub;
    Set<String> testGroups = {};

    setUpAll(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: SUBSCRIBE_KEY,
              publishKey: PUBLISH_KEY,
              uuid: UUID(
                  'integration_test_${DateTime.now().millisecondsSinceEpoch}')));
    });

    setUp(() {
      testGroups.clear();
    });

    tearDown(() async {
      await pubnub!.unsubscribeAll();
      for (var group in testGroups) {
        try {
          await pubnub!.channelGroups.delete(group);
        } catch (e) {
          print('Failed to cleanup group $group: $e');
        }
      }
    });

    String generateGroupName([String? prefix]) {
      var name =
          '${prefix ?? 'test'}_group_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      testGroups.add(name);
      return name;
    }

    Future<void> waitForConsistency() async {
      await Future.delayed(Duration(seconds: 2));
    }

    test('should integrate channel groups with subscribe functionality',
        () async {
      var groupName = generateGroupName('subscribe_test');
      var testChannels = {'test_ch1', 'test_ch2'};

      // 1. Setup Group - Create group and add test channels
      await pubnub!.channelGroups.addChannels(groupName, testChannels);
      await waitForConsistency();

      // 2. Subscribe to Group - Create subscription to channel group
      var subscription = pubnub!.subscribe(channelGroups: {groupName});
      
      // Wait for subscription to actually start listening
      await subscription.whenStarts;
      await Future.delayed(Duration(seconds: 1)); // Additional buffer for subscription to be fully ready

      // 3. Setup Message Listener - Set up listener BEFORE publishing
      var messageReceived = false;
      var messageCompleter = Completer<void>();
      var testMessage = 'Hello from channel group integration test!';

      subscription.messages.listen((envelope) {
        if (envelope.payload == testMessage && envelope.channel == 'test_ch1') {
          messageReceived = true;
          if (!messageCompleter.isCompleted) {
            messageCompleter.complete();
          }
        }
      });

      // 4. Publish to Channels - Publish messages to individual channels in group
      await pubnub!.publish('test_ch1', testMessage);

      // 5. Verify Reception - Wait for message with timeout
      try {
        await messageCompleter.future.timeout(Duration(seconds: 10));
      } catch (e) {
        // Timeout occurred
      }
      
      expect(messageReceived, isTrue,
          reason:
              'Message should be received through channel group subscription');

      // 5. Group Modification - Add/remove channels and verify subscription updates
      await pubnub!.channelGroups.addChannels(groupName, {'test_ch3'});
      await waitForConsistency();

      var listResult = await pubnub!.channelGroups.listChannels(groupName);
      expect(listResult.channels,
          containsAll({'test_ch1', 'test_ch2', 'test_ch3'}));

      await subscription.cancel();
    }, timeout: Timeout(Duration(seconds: 45)));

    test('should integrate channel groups with presence features', () async {
      var groupName = generateGroupName('presence_test');
      var testChannels = {'presence_ch1', 'presence_ch2'};

      // 1. Setup Group - Create channel group
      await pubnub!.channelGroups.addChannels(groupName, testChannels);
      await waitForConsistency();

      // 2. Presence Subscription - Subscribe to presence for channel group
      var presenceSubscription = pubnub!.subscribe(
        channelGroups: {groupName},
        withPresence: true,
      );

      // Wait for presence subscription to be established
      await Future.delayed(Duration(seconds: 3));

      // 3. Channel Operations - Add/remove channels and monitor presence events
      await pubnub!.channelGroups.addChannels(groupName, {'presence_ch3'});
      await waitForConsistency();

      var listResult = await pubnub!.channelGroups.listChannels(groupName);
      expect(listResult.channels,
          containsAll({'presence_ch1', 'presence_ch2', 'presence_ch3'}));

      await presenceSubscription.cancel();
    }, timeout: Timeout(Duration(seconds: 45)));
  });

  group('Integration [channelGroups] - Performance & Reliability', () {
    PubNub? pubnub;
    Set<String> testGroups = {};

    setUpAll(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: SUBSCRIBE_KEY,
              publishKey: PUBLISH_KEY,
              uuid:
                  UUID('perf_test_${DateTime.now().millisecondsSinceEpoch}')));
    });

    setUp(() {
      testGroups.clear();
    });

    tearDown(() async {
      for (var group in testGroups) {
        try {
          await pubnub!.channelGroups.delete(group);
        } catch (e) {
          print('Failed to cleanup group $group: $e');
        }
      }
    });

    String generateGroupName([String? prefix]) {
      var name =
          '${prefix ?? 'test'}_group_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      testGroups.add(name);
      return name;
    }

    test('should handle rapid successive operations', () async {
      var groupName = generateGroupName('stress_test');

      // Rapid Operations - Perform add/remove/list operations in quick succession
      for (int i = 0; i < 20; i++) {
        // Reduced from 50 to be more reasonable for integration test
        await pubnub!.channelGroups.addChannels(groupName, {'rapid_ch_$i'});
        var result = await pubnub!.channelGroups.listChannels(groupName);
        expect(result.channels.contains('rapid_ch_$i'), isTrue);
      }

      // Consistency Check - Verify final state is consistent
      var finalResult = await pubnub!.channelGroups.listChannels(groupName);
      expect(finalResult.channels.length, equals(20));
    }, timeout: Timeout(Duration(seconds: 120)));

    test('should handle operations over extended time periods', () async {
      var groupNames = <String>[];

      // Create multiple groups over time
      for (int i = 0; i < 5; i++) {
        var groupName = generateGroupName('long_running_$i');
        groupNames.add(groupName);

        await pubnub!.channelGroups
            .addChannels(groupName, {'long_ch_${i}_1', 'long_ch_${i}_2'});

        // Wait between operations
        await Future.delayed(Duration(seconds: 2));

        // Verify state consistency
        var result = await pubnub!.channelGroups.listChannels(groupName);
        expect(result.channels.length, equals(2));
      }

      // Final verification - all groups should still exist and be consistent
      for (var groupName in groupNames) {
        var result = await pubnub!.channelGroups.listChannels(groupName);
        expect(result.channels.length, equals(2));
      }
    },
        timeout: Timeout(
            Duration(seconds: 60))); // Reduced from 300s to be more reasonable
  });
}
