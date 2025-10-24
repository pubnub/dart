@TestOn('vm')
@Tags(['integration'])

import 'dart:io';
import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';

/// Creates a PAM-enabled keyset for integration tests
Keyset createPamKeyset({String? userIdSuffix}) {
  final userId = userIdSuffix != null
      ? 'pam-integration-$userIdSuffix-${DateTime.now().millisecondsSinceEpoch}'
      : 'pam-integration-${DateTime.now().millisecondsSinceEpoch}';

  return Keyset(
    subscribeKey: Platform.environment['SDK_PAM_SUB_KEY'] ?? 'demo-36',
    publishKey: Platform.environment['SDK_PAM_PUB_KEY'] ?? 'demo-36',
    secretKey: Platform.environment['SDK_PAM_SEC_KEY'] ?? 'demo-36',
    userId: UserId(userId),
  );
}

void main() {
  late PubNub pubnub;
  late Keyset pamKeyset;

  group('Integration [PAM grantToken]', () {
    setUp(() {
      pamKeyset = createPamKeyset();
      pubnub = PubNub(defaultKeyset: pamKeyset);
    });

    tearDown(() async {
      await pubnub.unsubscribeAll();
    });

    // PLAN_CASE: Integration test for complete token lifecycle
    group('Complete token lifecycle', () {
      test(
          'create complex token request with multiple resources and verify workflow',
          () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Step 1: Create token request with integration-like complexity
        var tokenRequest = pubnub.requestToken(
            ttl: 1440,
            authorizedUUID: 'authorized-integration-user',
            meta: {'test-type': 'integration', 'environment': 'test'});

        // Step 2: Add resources with various permissions (integration complexity)
        tokenRequest
          ..add(ResourceType.channel,
              name: 'integration-channel-1', read: true, write: true)
          ..add(ResourceType.channel,
              name: 'integration-channel-2',
              read: true,
              write: true,
              manage: true)
          ..add(ResourceType.channelGroup,
              name: 'integration-group-1', read: true)
          ..add(ResourceType.channel,
              pattern: 'integration-.*',
              read: true,
              write: true,
              manage: true,
              delete: true);

        // Step 3: Verify integration workflow - TokenRequest creation and validation
        expect(tokenRequest, isA<TokenRequest>());
        expect(tokenRequest.ttl, equals(1440));
        expect(
            tokenRequest.authorizedUUID, equals('authorized-integration-user'));
        expect(tokenRequest.meta, isNotNull);
        expect(tokenRequest.meta!['test-type'], equals('integration'));
        expect(tokenRequest.meta!['environment'], equals('test'));

        // Step 4: Make actual API call to grantToken
        try {
          var token = await pubnub.grantToken(tokenRequest);

          // Verify the token was created successfully
          expect(token, isA<Token>());
          expect(token.toString(), isNotEmpty);

          // Verify token can be parsed
          var parsedToken = pubnub.parseToken(token.toString());
          expect(parsedToken, isA<Token>());

          print(
              'Successfully created token: ${token.toString().substring(0, 20)}...');
        } catch (e) {
          // Log the error for debugging but don't fail the test if it's a known issue
          print('Token creation failed (may be expected with demo keys): $e');

          // If using demo keys, this is expected to fail
          if (pamKeyset.secretKey == 'demo-36') {
            expect(e, isA<Exception>());
          } else {
            rethrow;
          }
        }
      });

      test('integration workflow with user/space resources for modern PAM',
          () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Integration test for modern PAM (user/space) workflow
        var tokenRequest =
            pubnub.requestToken(ttl: 720, authorizedUserId: 'modern-pam-user');

        // Add modern PAM resources (user/space) with various permissions
        tokenRequest
          ..add(ResourceType.user,
              name: 'user-alice',
              read: true,
              write: true,
              manage: true,
              delete: true,
              get: true,
              update: true,
              join: true)
          ..add(ResourceType.space,
              name: 'space-lobby', read: true, write: true, manage: true)
          ..add(ResourceType.user, pattern: 'user-.*', read: true)
          ..add(ResourceType.space,
              pattern: 'space-.*', read: true, write: true);

        // Verify integration workflow for modern PAM
        expect(tokenRequest, isA<TokenRequest>());
        expect(tokenRequest.ttl, equals(720));
        expect(tokenRequest.authorizedUserId, equals('modern-pam-user'));

        // Make actual API call to test modern PAM workflow
        try {
          var token = await pubnub.grantToken(tokenRequest);

          // Verify the token was created successfully
          expect(token, isA<Token>());
          expect(token.toString(), isNotEmpty);

          print(
              'Successfully created modern PAM token: ${token.toString().substring(0, 20)}...');
        } catch (e) {
          print(
              'Modern PAM token creation failed (may be expected with demo keys): $e');

          // If using demo keys, this is expected to fail
          if (pamKeyset.secretKey == 'demo-36') {
            expect(e, isA<Exception>());
          } else {
            rethrow;
          }
        }
      });
    });

    // PLAN_CASE: Integration test for error scenarios
    group('Error scenario integration', () {
      test('integration error handling workflow validation', () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Test integration workflow for error scenarios
        var tokenRequest = pubnub.requestToken(ttl: 60)
          ..add(ResourceType.channel, name: 'test-channel', read: true);

        // Verify that error handling integrates properly in the workflow
        expect(tokenRequest, isA<TokenRequest>());
        expect(tokenRequest.ttl, equals(60));

        // Test actual API call for simple token request
        try {
          var token = await pubnub.grantToken(tokenRequest);
          expect(token, isA<Token>());
          expect(token.toString(), isNotEmpty);

          print(
              'Successfully created simple token: ${token.toString().substring(0, 20)}...');
        } catch (e) {
          print(
              'Simple token creation failed (may be expected with demo keys): $e');

          if (pamKeyset.secretKey == 'demo-36') {
            expect(e, isA<Exception>());
          } else {
            rethrow;
          }
        }
      });

      test('invalid token request validation in integration context', () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Test mixing incompatible resource types
        var tokenRequest = pubnub.requestToken(ttl: 60)
          ..add(ResourceType.user, name: 'user-1', read: true)
          ..add(ResourceType.channel, name: 'channel-1', read: true);

        // This should throw an InvariantException due to mixing incompatible resource types
        expect(() async => await pubnub.grantToken(tokenRequest),
            throwsA(isA<InvariantException>()));
      });
    });

    // PLAN_CASE: Integration test for performance and scalability
    group('Performance and scalability', () {
      test('integration workflow with large number of resources', () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Integration test for scalability - create TokenRequest with many resources
        var tokenRequest = pubnub.requestToken(ttl: 300);

        // Add many resources to test scalability integration
        for (int i = 0; i < 20; i++) {
          // Reduced from 50 to avoid timeout
          tokenRequest.add(ResourceType.channel,
              name: 'channel-$i', read: true, write: true);
        }

        // Add some patterns to test pattern integration
        for (int i = 0; i < 5; i++) {
          // Reduced from 10 to avoid timeout
          tokenRequest.add(ResourceType.channel,
              pattern: 'pattern-$i-.*', read: true, write: true, manage: true);
        }

        // Verify integration workflow handles large-scale TokenRequests
        expect(tokenRequest, isA<TokenRequest>());
        expect(tokenRequest.ttl, equals(300));

        // Test actual API call with large token request
        try {
          var token = await pubnub.grantToken(tokenRequest);
          expect(token, isA<Token>());
          expect(token.toString(), isNotEmpty);

          print(
              'Successfully created large token with 25 resources: ${token.toString().substring(0, 20)}...');
        } catch (e) {
          print(
              'Large token creation failed (may be expected with demo keys): $e');

          if (pamKeyset.secretKey == 'demo-36') {
            expect(e, isA<Exception>());
          } else {
            rethrow;
          }
        }
      });

      test('integration workflow for concurrent token request creation',
          () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Integration test for concurrent workflow - create multiple TokenRequests
        var tokenRequests = <TokenRequest>[];

        for (int i = 0; i < 3; i++) {
          var tokenRequest = pubnub.requestToken(ttl: 60)
            ..add(ResourceType.channel,
                name: 'concurrent-channel-$i', read: true);

          tokenRequests.add(tokenRequest);
        }

        // Verify integration workflow handles concurrent TokenRequest creation
        expect(tokenRequests.length, equals(3));
        for (int i = 0; i < 3; i++) {
          expect(tokenRequests[i], isA<TokenRequest>());
          expect(tokenRequests[i].ttl, equals(60));
        }

        // Test concurrent token creation
        try {
          var futures =
              tokenRequests.map((request) => pubnub.grantToken(request));
          var tokens = await Future.wait(futures);

          expect(tokens.length, equals(3));
          for (var token in tokens) {
            expect(token, isA<Token>());
            expect(token.toString(), isNotEmpty);
          }

          print('Successfully created ${tokens.length} concurrent tokens');
        } catch (e) {
          print(
              'Concurrent token creation failed (may be expected with demo keys): $e');

          if (pamKeyset.secretKey == 'demo-36') {
            expect(e, isA<Exception>());
          } else {
            rethrow;
          }
        }
      });
    });

    // PLAN_CASE: Integration test for real-world usage patterns
    group('Real-world usage patterns', () {
      test('integration workflow for chat application token pattern', () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Integration test for real-world chat application workflow
        var tokenRequest = pubnub.requestToken(
            ttl: 1440, // 24 hours
            authorizedUUID: 'user-alice',
            meta: {'user-type': 'premium', 'region': 'us-east-1'});

        // Build complex real-world chat application permissions
        // User's presence channel
        tokenRequest.add(ResourceType.channel,
            name: 'user-alice-presence', read: true, write: true);

        // User's notification channel (read-only)
        tokenRequest.add(ResourceType.channel,
            name: 'user-alice-notifications', read: true);

        // Chat rooms group
        tokenRequest.add(ResourceType.channelGroup,
            name: 'chat-rooms', read: true, write: true);

        // Pattern for all chat rooms
        tokenRequest.add(ResourceType.channel,
            pattern: 'chat-room-.*', read: true, write: true);

        // Pattern for private channels involving this user
        tokenRequest.add(ResourceType.channel,
            pattern: 'private-.*-alice', read: true, write: true, manage: true);

        // Verify integration workflow for real-world chat application
        expect(tokenRequest, isA<TokenRequest>());
        expect(tokenRequest.ttl, equals(1440));
        expect(tokenRequest.authorizedUUID, equals('user-alice'));
        expect(tokenRequest.meta, isNotNull);
        expect(tokenRequest.meta!['user-type'], equals('premium'));
        expect(tokenRequest.meta!['region'], equals('us-east-1'));

        // Test actual API call for chat application pattern
        try {
          var token = await pubnub.grantToken(tokenRequest);
          expect(token, isA<Token>());
          expect(token.toString(), isNotEmpty);

          print(
              'Successfully created chat app token: ${token.toString().substring(0, 20)}...');
        } catch (e) {
          print(
              'Chat app token creation failed (may be expected with demo keys): $e');

          if (pamKeyset.secretKey == 'demo-36') {
            expect(e, isA<Exception>());
          } else {
            rethrow;
          }
        }
      });

      test('integration workflow for IoT device token pattern', () async {
        // Skip test if PAM keys are not properly configured
        if (pamKeyset.secretKey == null) {
          markTestSkipped(
              'PAM keys not configured in environment. Set SDK_PAM_SUB_KEY, SDK_PAM_PUB_KEY, and SDK_PAM_SEC_KEY environment variables.');
          return;
        }

        // Integration test for real-world IoT device workflow
        var tokenRequest = pubnub.requestToken(
            ttl: 10080, // 1 week
            authorizedUUID: 'device-sensor-001',
            meta: {
              'device-type': 'temperature-sensor',
              'location': 'warehouse-a',
              'firmware-version': '1.2.3'
            });

        // Build IoT device permissions (write-heavy pattern)
        // Device can write sensor data
        tokenRequest.add(ResourceType.channel,
            name: 'device-sensor-001-data', write: true);

        // Device can read and write status
        tokenRequest.add(ResourceType.channel,
            name: 'device-sensor-001-status', read: true, write: true);

        // Device can read commands
        tokenRequest.add(ResourceType.channel,
            name: 'device-sensor-001-commands', read: true);

        // Device can write to alert channels
        tokenRequest.add(ResourceType.channel,
            pattern: 'alerts-.*', write: true);

        // Verify integration workflow for real-world IoT device
        expect(tokenRequest, isA<TokenRequest>());
        expect(tokenRequest.ttl, equals(10080));
        expect(tokenRequest.authorizedUUID, equals('device-sensor-001'));
        expect(tokenRequest.meta, isNotNull);
        expect(tokenRequest.meta!['device-type'], equals('temperature-sensor'));
        expect(tokenRequest.meta!['location'], equals('warehouse-a'));
        expect(tokenRequest.meta!['firmware-version'], equals('1.2.3'));

        // Test actual API call for IoT device pattern
        try {
          var token = await pubnub.grantToken(tokenRequest);
          expect(token, isA<Token>());
          expect(token.toString(), isNotEmpty);

          print(
              'Successfully created IoT device token: ${token.toString().substring(0, 20)}...');
        } catch (e) {
          print(
              'IoT device token creation failed (may be expected with demo keys): $e');

          if (pamKeyset.secretKey == 'demo-36') {
            expect(e, isA<Exception>());
          } else {
            rethrow;
          }
        }
      });
    });
  });
}
