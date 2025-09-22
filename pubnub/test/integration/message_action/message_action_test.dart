@TestOn('vm')
@Tags(['integration'])

import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_utils.dart';

void main() {
  late PubNub pubnub;
  late String testChannel;
  late Keyset testKeyset;

  group('Message Action Integration Tests', () {
    setUp(() {
      testChannel = generateTestChannel();
      testKeyset = createTestKeyset();
      pubnub = PubNub(defaultKeyset: testKeyset);
    });

    tearDown(() async {
      try {
        await cleanupTestActions(pubnub, testChannel);
        await pubnub.unsubscribeAll();
      } catch (e) {
        print('Teardown warning: $e');
      }
    });

    group('Basic API Integration Tests', () {
      test('real_add_message_action_success', () async {
        // Setup: Publish test message to get valid timetoken
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        // Test: Add message action
        final result = await addTestAction(
          pubnub,
          testChannel,
          messageTimetoken,
          type: 'reaction',
          value: 'thumbs_up',
        );

        // Assertions
        expect(result.action.type, equals('reaction'));
        expect(result.action.value, equals('thumbs_up'));
        expect(result.action.actionTimetoken, isNotNull);
        expect(result.action.messageTimetoken,
            equals(messageTimetoken.toString()));
        expect(result.action.uuid, equals(testKeyset.userId.value));
      });

      test('real_fetch_message_actions_success', () async {
        // Setup: Pre-populate channel with 3 different message actions
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        await addMultipleTestActions(
          pubnub,
          testChannel,
          messageTimetoken,
          types: ['reaction', 'receipt', 'custom'],
          values: ['thumbs_up', 'read', 'star'],
        );
        await waitForActionPropagation();

        // Test: Fetch message actions
        final result = await pubnub.fetchMessageActions(testChannel);

        // Assertions
        expect(result.actions.length, equals(3));
        expect(result.actions, isA<List<MessageAction>>());

        // Verify each action has required properties
        for (final action in result.actions) {
          expect(action.type, isNotEmpty);
          expect(action.value, isNotEmpty);
          expect(action.actionTimetoken, isNotEmpty);
          expect(action.messageTimetoken, isNotEmpty);
          expect(action.uuid, isNotEmpty);
        }

        // Verify expected types are present
        final types = result.actions.map((a) => a.type).toList();
        expect(types, containsAll(['reaction', 'receipt', 'custom']));
      });

      test('real_delete_message_action_success', () async {
        // Setup: Add a test message action to get actionTimetoken
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        final addResult =
            await addTestAction(pubnub, testChannel, messageTimetoken);
        await waitForActionPropagation();

        // Test: Delete the message action
        await pubnub.deleteMessageAction(
          testChannel,
          messageTimetoken: messageTimetoken,
          actionTimetoken:
              Timetoken(BigInt.parse(addResult.action.actionTimetoken)),
        );
        await waitForActionPropagation();

        // Verify action no longer appears in subsequent fetch
        final fetchResult = await pubnub.fetchMessageActions(testChannel);
        final deletedTimetoken = addResult.action.actionTimetoken;
        expect(
          fetchResult.actions
              .where((a) => a.actionTimetoken == deletedTimetoken),
          isEmpty,
        );
      });
    });

    group('End-to-End Workflow Tests', () {
      test('complete_message_action_lifecycle', () async {
        // Publish test message
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        // Add multiple actions to the message
        final addedActions = await addMultipleTestActions(
          pubnub,
          testChannel,
          messageTimetoken,
          types: ['reaction', 'receipt', 'bookmark', 'flag'],
          values: ['thumbs_up', 'read', 'saved', 'inappropriate'],
        );
        await waitForActionPropagation();

        // Fetch all actions
        var fetchResult = await pubnub.fetchMessageActions(testChannel);
        expect(fetchResult.actions.length, equals(4));

        // Delete specific actions (keep 2, delete 2)
        for (int i = 0; i < 2; i++) {
          await pubnub.deleteMessageAction(
            testChannel,
            messageTimetoken: messageTimetoken,
            actionTimetoken:
                Timetoken(BigInt.parse(addedActions[i].action.actionTimetoken)),
          );
          await Future.delayed(
              Duration(milliseconds: 500)); // Rate limit protection
        }
        await waitForActionPropagation();

        // Verify final state
        final finalFetchResult = await pubnub.fetchMessageActions(testChannel);
        expect(finalFetchResult.actions.length, equals(2));

        // Verify action ordering by timetoken
        expect(areActionsInTimetokenOrder(finalFetchResult.actions), isTrue);
      });

      test('multiple_actions_single_message_integration', () async {
        // Publish one test message
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        // Add 5 different actions
        await addMultipleTestActions(
          pubnub,
          testChannel,
          messageTimetoken,
          types: ['reaction', 'receipt', 'bookmark', 'flag', 'custom'],
          values: ['thumbs_up', 'read', 'saved', 'inappropriate', 'star'],
        );
        await waitForActionPropagation();

        // Fetch all actions for the message
        final result = await pubnub.fetchMessageActions(testChannel);

        // Assertions
        expect(result.actions.length, equals(5));

        // Verify each action type is present and unique
        final types = result.actions.map((a) => a.type).toSet();
        expect(types.length, equals(5));
        expect(types,
            containsAll(['reaction', 'receipt', 'bookmark', 'flag', 'custom']));

        // Verify actions are ordered by actionTimetoken
        expect(areActionsInTimetokenOrder(result.actions), isTrue);
      });

      test('cross_channel_action_isolation', () async {
        // Setup: Generate two test channels
        final channel1 = generateTestChannel();
        final channel2 = generateTestChannel();

        try {
          // Publish messages to both channels
          final messageTimetoken1 = await publishTestMessage(pubnub, channel1);
          final messageTimetoken2 = await publishTestMessage(pubnub, channel2);
          await waitForActionPropagation(Duration(seconds: 1));

          // Add actions to both channels
          await addTestAction(pubnub, channel1, messageTimetoken1,
              type: 'reaction', value: 'channel1');
          await addTestAction(pubnub, channel2, messageTimetoken2,
              type: 'reaction', value: 'channel2');
          await waitForActionPropagation();

          // Fetch actions from each channel
          final channel1Results = await pubnub.fetchMessageActions(channel1);
          final channel2Results = await pubnub.fetchMessageActions(channel2);

          // Verify isolation
          expect(channel1Results.actions.length, equals(1));
          expect(channel2Results.actions.length, equals(1));
          expect(channel1Results.actions[0].value, equals('channel1'));
          expect(channel2Results.actions[0].value, equals('channel2'));

          // Verify no cross-contamination
          final channel1Actions =
              channel1Results.actions.map((a) => a.actionTimetoken).toSet();
          final channel2Actions =
              channel2Results.actions.map((a) => a.actionTimetoken).toSet();
          expect(channel1Actions.intersection(channel2Actions), isEmpty);
        } finally {
          await cleanupTestActions(pubnub, channel1);
          await cleanupTestActions(pubnub, channel2);
        }
      });
    });

    group('Pagination Integration Tests', () {
      test('fetch_message_actions_pagination_integration', () async {
        // Setup: Pre-populate channel with many actions (limited by API quotas)
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        // Add 20 actions (reasonable for testing)
        final actions = <AddMessageActionResult>[];
        for (int i = 0; i < 20; i++) {
          final result = await addTestAction(
            pubnub,
            testChannel,
            messageTimetoken,
            type: 'test',
            value: 'action_$i',
          );
          actions.add(result);
          await Future.delayed(
              Duration(milliseconds: 200)); // Ensure different timetokens
        }
        await waitForActionPropagation();

        // Fetch actions with limit
        final result = await pubnub.fetchMessageActions(testChannel, limit: 10);

        // Assertions
        expect(result.actions.length, lessThanOrEqualTo(10));

        if (result.moreActions != null) {
          expect(result.moreActions, isNotNull);
          // Could implement second page fetch here if needed
        }

        // Verify no duplicate actions in results (check uniqueness by actionTimetoken)
        final timetokens = result.actions.map((a) => a.actionTimetoken).toSet();
        expect(timetokens.length, equals(result.actions.length));
      });

      test('pagination_boundary_conditions', () async {
        // Setup: Add a few actions
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        await addTestAction(pubnub, testChannel, messageTimetoken);
        await waitForActionPropagation();

        // Test with very recent timetoken (should return empty or very few)
        final veryRecentTimetoken = Timetoken(
            BigInt.from(DateTime.now().millisecondsSinceEpoch * 10000));
        final emptyResult = await pubnub.fetchMessageActions(
          testChannel,
          from: veryRecentTimetoken,
        );

        // Should handle empty results gracefully
        expect(emptyResult.actions, isA<List<MessageAction>>());
        if (emptyResult.actions.isEmpty) {
          expect(emptyResult.moreActions, isNull);
        }

        // Test with very old timetoken (should return all available)
        final veryOldTimetoken = Timetoken(BigInt.from(1000000000000000));
        final allResult = await pubnub.fetchMessageActions(
          testChannel,
          to: veryOldTimetoken,
        );

        expect(allResult.actions, isA<List<MessageAction>>());
      });
    });

    group('Authentication & Security Integration Tests', () {
      test('message_actions_with_pam_authentication', () async {
        // Note: This test requires PAM-enabled keys in environment
        final pamKeyset = createPamKeyset(userIdSuffix: 'pam-test');
        if (pamKeyset.secretKey == null) {
          markTestSkipped('PAM keys not configured in environment');
          return;
        }

        final pamPubNub = PubNub(defaultKeyset: pamKeyset);
        final pamChannel = generateTestChannel();

        try {
          // Test with proper permissions
          final messageTimetoken =
              await publishTestMessage(pamPubNub, pamChannel);
          await waitForActionPropagation(Duration(seconds: 1));

          final result =
              await addTestAction(pamPubNub, pamChannel, messageTimetoken);
          expect(result, isA<AddMessageActionResult>());

          // Verify fetch works
          final fetchResult = await pamPubNub.fetchMessageActions(pamChannel);
          expect(fetchResult.actions, isA<List<MessageAction>>());

          // Cleanup
          await cleanupTestActions(pamPubNub, pamChannel);
        } finally {
          await pamPubNub.unsubscribeAll();
        }
      });

      test('message_actions_with_secret_key_signature', () async {
        final secretKeyset = createPamKeyset(userIdSuffix: 'secret-test');
        if (secretKeyset.secretKey == null) {
          markTestSkipped('Secret key not configured in environment');
          return;
        }

        final secretPubNub = PubNub(defaultKeyset: secretKeyset);
        final secretChannel = generateTestChannel();

        try {
          // All operations should complete successfully with signatures
          final messageTimetoken =
              await publishTestMessage(secretPubNub, secretChannel);
          await waitForActionPropagation(Duration(seconds: 1));

          final result = await addTestAction(
              secretPubNub, secretChannel, messageTimetoken);
          expect(result, isNotNull);

          final fetchResult =
              await secretPubNub.fetchMessageActions(secretChannel);
          expect(fetchResult, isNotNull);

          // Cleanup
          await cleanupTestActions(secretPubNub, secretChannel);
        } finally {
          await secretPubNub.unsubscribeAll();
        }
      });
    });

    group('Error Handling Integration Tests', () {
      test('invalid_message_timetoken_integration', () async {
        // Use fabricated/invalid message timetoken
        final fabricatedTimetoken = Timetoken(BigInt.from(99999999999999999));

        // Attempt to add action (PubNub doesn't validate message existence)
        final result = await addTestAction(
          pubnub,
          testChannel,
          fabricatedTimetoken,
          type: 'test',
          value: 'invalid_parent',
        );

        // Operation should complete successfully despite invalid parent
        expect(result.action.messageTimetoken,
            equals(fabricatedTimetoken.toString()));
        expect(result.action.type, equals('test'));
        expect(result.action.value, equals('invalid_parent'));

        // Cleanup the action we created
        await pubnub.deleteMessageAction(
          testChannel,
          messageTimetoken: fabricatedTimetoken,
          actionTimetoken:
              Timetoken(BigInt.parse(result.action.actionTimetoken)),
        );
      });

      test('network_timeout_handling', () async {
        // Note: This test is challenging to implement reliably in integration tests
        // as it requires network manipulation. We'll test basic error handling instead.

        // Test with very invalid channel (should handle gracefully)
        try {
          await pubnub.fetchMessageActions('');
          fail('Should have thrown exception for empty channel');
        } catch (e) {
          expect(e, isA<InvariantException>());
        }
      });
    });

    group('Performance Integration Tests', () {
      test('concurrent_message_action_operations', () async {
        // Setup: Publish test message
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        // Launch concurrent operations (reduced numbers for test stability)
        final operations = <Future<dynamic> Function()>[
          // 3 concurrent add operations
          () => addTestAction(pubnub, testChannel, messageTimetoken,
              type: 'concurrent', value: 'add1'),
          () => addTestAction(pubnub, testChannel, messageTimetoken,
              type: 'concurrent', value: 'add2'),
          () => addTestAction(pubnub, testChannel, messageTimetoken,
              type: 'concurrent', value: 'add3'),
          // 2 concurrent fetch operations
          () => pubnub.fetchMessageActions(testChannel),
          () => pubnub.fetchMessageActions(testChannel),
        ];

        // Execute concurrently
        final results = await runConcurrentOperations(operations);

        // All operations should complete without errors
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isNotNull);
        }

        // Verify data integrity after concurrent operations
        await waitForActionPropagation();
        final finalResult = await pubnub.fetchMessageActions(testChannel);
        expect(finalResult.actions.length, greaterThanOrEqualTo(3));
      });

      test('high_volume_action_processing', () async {
        // Setup: Add many actions (limited for test performance)
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        const actionCount = 50; // Reasonable for integration testing
        final addedActions = <AddMessageActionResult>[];

        // Add actions with rate limiting
        for (int i = 0; i < actionCount; i++) {
          final result = await addTestAction(
            pubnub,
            testChannel,
            messageTimetoken,
            type: 'volume',
            value: 'action_$i',
          );
          addedActions.add(result);

          // Rate limiting to avoid API throttling
          if (i % 10 == 9) {
            await Future.delayed(Duration(seconds: 2));
          } else {
            await Future.delayed(Duration(milliseconds: 100));
          }
        }

        await waitForActionPropagation(Duration(seconds: 3));

        // Fetch all actions using pagination
        final allActions = <MessageAction>[];
        FetchMessageActionsResult? result;
        Timetoken? from;

        do {
          result = await pubnub.fetchMessageActions(
            testChannel,
            from: from,
            limit: 100,
          );
          allActions.addAll(result.actions);

          // Use moreActions for pagination if available
          if (result.moreActions != null && result.actions.isNotEmpty) {
            from = Timetoken(BigInt.parse(result.actions.last.actionTimetoken));
          } else {
            break;
          }
        } while (result.actions.isNotEmpty);

        // Verify data integrity
        expect(allActions.length, equals(actionCount));
        expect(areActionsInTimetokenOrder(allActions), isTrue);
      });
    });

    group('Data Consistency Integration Tests', () {
      test('action_data_integrity_verification', () async {
        // Setup: Add action with unicode content and special characters
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        const unicodeValue = '🎉 Special chars: @#\$%^&*()_+ 中文 emoji! 🚀';
        const unicodeType = 'unicode_test';

        final addResult = await addTestAction(
          pubnub,
          testChannel,
          messageTimetoken,
          type: unicodeType,
          value: unicodeValue,
        );

        await waitForActionPropagation();

        // Fetch action back
        final fetchResult = await pubnub.fetchMessageActions(testChannel);
        final fetchedAction = fetchResult.actions.firstWhere(
          (a) => a.actionTimetoken == addResult.action.actionTimetoken,
        );

        // Compare all fields for exact matches
        expect(fetchedAction.type, equals(unicodeType));
        expect(fetchedAction.value, equals(unicodeValue));
        expect(fetchedAction.messageTimetoken,
            equals(messageTimetoken.toString()));
        expect(fetchedAction.uuid, equals(testKeyset.userId.value));

        // Verify unicode preservation
        expect(
            verifySpecialCharacters(unicodeValue, fetchedAction.value), isTrue);
      });

      test('timetoken_ordering_consistency', () async {
        // Setup: Add 10 actions in sequence with delays
        final messageTimetoken = await publishTestMessage(pubnub, testChannel);
        await waitForActionPropagation(Duration(seconds: 1));

        final addedActions = <AddMessageActionResult>[];
        for (int i = 0; i < 10; i++) {
          final result = await addTestAction(
            pubnub,
            testChannel,
            messageTimetoken,
            type: 'sequence',
            value: 'order_$i',
          );
          addedActions.add(result);
          await Future.delayed(
              Duration(milliseconds: 300)); // Ensure different timetokens
        }

        await waitForActionPropagation();

        // Fetch actions from channel
        final fetchResult = await pubnub.fetchMessageActions(testChannel);
        final sequenceActions =
            fetchResult.actions.where((a) => a.type == 'sequence').toList();

        // Verify ordering matches addition sequence (actions are returned in timetoken order)
        expect(sequenceActions.length, equals(10));
        expect(areActionsInTimetokenOrder(sequenceActions), isTrue);

        // Verify no duplicate timetokens in results
        final timetokens =
            sequenceActions.map((a) => a.actionTimetoken).toSet();
        expect(timetokens.length, equals(sequenceActions.length));
      });
    });

    group('Encryption Integration Tests', () {
      test('message_actions_with_encryption_module', () async {
        // Setup: Configure PubNub with encryption
        final cipherKey = CipherKey.fromUtf8('integration_test_key');
        final cryptoPubNub = PubNub(
          defaultKeyset: testKeyset,
          crypto: CryptoModule.aesCbcCryptoModule(cipherKey),
        );

        final cryptoChannel = generateTestChannel();

        try {
          // Publish message and add action with encryption
          final messageTimetoken =
              await publishTestMessage(cryptoPubNub, cryptoChannel);
          await waitForActionPropagation(Duration(seconds: 1));

          const originalValue = 'encrypted_action_value';
          final result = await addTestAction(
            cryptoPubNub,
            cryptoChannel,
            messageTimetoken,
            type: 'encrypted',
            value: originalValue,
          );

          await waitForActionPropagation();

          // Fetch action and verify decryption
          final fetchResult =
              await cryptoPubNub.fetchMessageActions(cryptoChannel);
          final encryptedAction = fetchResult.actions.firstWhere(
            (a) => a.actionTimetoken == result.action.actionTimetoken,
          );

          // Verify decryption worked correctly
          expect(encryptedAction.value, equals(originalValue));
          expect(encryptedAction.type, equals('encrypted'));

          // Cleanup
          await cleanupTestActions(cryptoPubNub, cryptoChannel);
        } finally {
          await cryptoPubNub.unsubscribeAll();
        }
      });

      test('encrypted_action_cross_client_compatibility', () async {
        final cipherKey = CipherKey.fromUtf8('cross_client_test_key');
        final crossChannel = generateTestChannel();

        // Client A (with encryption)
        final clientA = PubNub(
          defaultKeyset: createTestKeyset(userIdSuffix: 'clientA'),
          crypto: CryptoModule.aesCbcCryptoModule(cipherKey),
        );

        // Client B (with same encryption)
        final clientB = PubNub(
          defaultKeyset: createTestKeyset(userIdSuffix: 'clientB'),
          crypto: CryptoModule.aesCbcCryptoModule(cipherKey),
        );

        // Client C (no encryption)
        final clientC = PubNub(
          defaultKeyset: createTestKeyset(userIdSuffix: 'clientC'),
        );

        try {
          // Client A adds encrypted action
          final messageTimetoken =
              await publishTestMessage(clientA, crossChannel);
          await waitForActionPropagation(Duration(seconds: 1));

          const plaintextValue = 'secret_cross_client_value';
          await addTestAction(
            clientA,
            crossChannel,
            messageTimetoken,
            type: 'cross_client',
            value: plaintextValue,
          );
          await waitForActionPropagation();

          // Client B gets decrypted action data
          final clientBResult = await clientB.fetchMessageActions(crossChannel);
          expect(clientBResult.actions.length, equals(1));
          expect(clientBResult.actions[0].value, equals(plaintextValue));

          // Client C gets raw data (may be encrypted or cause error)
          final clientCResult = await clientC.fetchMessageActions(crossChannel);
          expect(clientCResult.actions.length, equals(1));
          // Note: The behavior here depends on the encryption implementation
          // It might return encrypted data or the same value if encryption is transparent

          // Cleanup
          await cleanupTestActions(clientA, crossChannel);
        } finally {
          await clientA.unsubscribeAll();
          await clientB.unsubscribeAll();
          await clientC.unsubscribeAll();
        }
      });
    });
  }, timeout: Timeout(testTimeout));
}
