@TestOn('vm')
@Tags(['integration'])

import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';

import '_pam_client.dart';

void main() {
  late PubNub pubnub;

  group('Integration [PAM grantToken]', () {
    setUp(() {
      pubnub = createPamClient(
          userId: 'pam-integration-${DateTime.now().millisecondsSinceEpoch}');
    });

    group('Complete token lifecycle', () {
      test('grants a token for multiple resources and parses it back',
          () async {
        var tokenRequest = pubnub.requestToken(
            ttl: 1440,
            authorizedUUID: 'authorized-integration-user',
            meta: {'test-type': 'integration', 'environment': 'test'})
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

        expect(tokenRequest.ttl, equals(1440));
        expect(
            tokenRequest.authorizedUUID, equals('authorized-integration-user'));
        expect(tokenRequest.meta!['test-type'], equals('integration'));

        var token = await pubnub.grantToken(tokenRequest);
        expect(token.toString(), isNotEmpty);

        var parsed = pubnub.parseToken(token.toString());
        expect(parsed.ttl, equals(1440));
        expect(parsed.authorizedUUID, equals('authorized-integration-user'));
        expect(parsed.meta['test-type'], equals('integration'));
        expect(parsed.resources.where((r) => r.type == ResourceType.channel),
            isNotEmpty);
        expect(parsed.patterns.where((r) => r.pattern == 'integration-.*'),
            isNotEmpty);
      });

      test('grants a token for user and space resources', () async {
        var tokenRequest = pubnub.requestToken(
            ttl: 720, authorizedUserId: 'modern-pam-user')
          ..add(ResourceType.user,
              name: 'user-alice',
              create: true,
              delete: true,
              get: true,
              update: true)
          ..add(ResourceType.space,
              name: 'space-lobby', read: true, write: true, manage: true)
          ..add(ResourceType.user, pattern: 'user-.*', get: true)
          ..add(ResourceType.space,
              pattern: 'space-.*', read: true, write: true);

        expect(tokenRequest.ttl, equals(720));
        expect(tokenRequest.authorizedUserId, equals('modern-pam-user'));

        var token = await pubnub.grantToken(tokenRequest);
        expect(token.toString(), isNotEmpty);

        var parsed = pubnub.parseToken(token.toString());
        expect(parsed.authorizedUUID, equals('modern-pam-user'));
        expect(parsed.resources.where((r) => r.type == ResourceType.user),
            isNotEmpty);
      });
    });

    group('Validation', () {
      test('grants a simple single resource token', () async {
        var tokenRequest = pubnub.requestToken(ttl: 60)
          ..add(ResourceType.channel, name: 'test-channel', read: true);

        var token = await pubnub.grantToken(tokenRequest);
        expect(token.toString(), isNotEmpty);
      });

      test('rejects mixing the user and uuid scopes', () async {
        var tokenRequest = pubnub.requestToken(ttl: 60)
          ..add(ResourceType.user, name: 'user-1', get: true)
          ..add(ResourceType.uuid, name: 'uuid-1', get: true);

        expect(pubnub.grantToken(tokenRequest),
            throwsA(isA<InvariantException>()));
      });

      test('rejects mixing the space and channel scopes', () async {
        var tokenRequest = pubnub.requestToken(ttl: 60)
          ..add(ResourceType.space, name: 'space-1', read: true)
          ..add(ResourceType.channel, name: 'channel-1', read: true);

        expect(pubnub.grantToken(tokenRequest),
            throwsA(isA<InvariantException>()));
      });

      test('rejects a grant without resources or projections', () async {
        var tokenRequest = pubnub.requestToken(ttl: 60);

        expect(pubnub.grantToken(tokenRequest),
            throwsA(isA<InvariantException>()));
      });
    });

    group('Scalability', () {
      test('grants a token with many resources and patterns', () async {
        var tokenRequest = pubnub.requestToken(ttl: 300);

        for (var i = 0; i < 20; i++) {
          tokenRequest.add(ResourceType.channel,
              name: 'channel-$i', read: true, write: true);
        }

        for (var i = 0; i < 5; i++) {
          tokenRequest.add(ResourceType.channel,
              pattern: 'pattern-$i-.*', read: true, write: true, manage: true);
        }

        var token = await pubnub.grantToken(tokenRequest);
        var parsed = pubnub.parseToken(token.toString());

        expect(parsed.resources.where((r) => r.type == ResourceType.channel),
            hasLength(20));
        expect(parsed.patterns.where((r) => r.type == ResourceType.channel),
            hasLength(5));
      });

      test('grants multiple tokens concurrently', () async {
        var tokenRequests = [
          for (var i = 0; i < 3; i++)
            pubnub.requestToken(ttl: 60)
              ..add(ResourceType.channel,
                  name: 'concurrent-channel-$i', read: true)
        ];

        var tokens = await Future.wait(
            tokenRequests.map((request) => pubnub.grantToken(request)));

        expect(tokens, hasLength(3));
        for (var token in tokens) {
          expect(token.toString(), isNotEmpty);
        }
      });
    });

    group('Real-world usage patterns', () {
      test('grants a chat application token', () async {
        var tokenRequest = pubnub.requestToken(
            ttl: 1440,
            authorizedUUID: 'user-alice',
            meta: {'user-type': 'premium', 'region': 'us-east-1'})
          ..add(ResourceType.channel,
              name: 'user-alice-presence', read: true, write: true)
          ..add(ResourceType.channel,
              name: 'user-alice-notifications', read: true)
          ..add(ResourceType.channelGroup,
              name: 'chat-rooms', read: true, write: true)
          ..add(ResourceType.channel,
              pattern: 'chat-room-.*', read: true, write: true)
          ..add(ResourceType.channel,
              pattern: 'private-.*-alice',
              read: true,
              write: true,
              manage: true);

        var token = await pubnub.grantToken(tokenRequest);
        var parsed = pubnub.parseToken(token.toString());

        expect(parsed.authorizedUUID, equals('user-alice'));
        expect(parsed.meta['user-type'], equals('premium'));
        expect(parsed.meta['region'], equals('us-east-1'));
      });

      test('grants an IoT device token', () async {
        var tokenRequest = pubnub.requestToken(
            ttl: 10080,
            authorizedUUID: 'device-sensor-001',
            meta: {
              'device-type': 'temperature-sensor',
              'location': 'warehouse-a',
              'firmware-version': '1.2.3'
            })
          ..add(ResourceType.channel,
              name: 'device-sensor-001-data', write: true)
          ..add(ResourceType.channel,
              name: 'device-sensor-001-status', read: true, write: true)
          ..add(ResourceType.channel,
              name: 'device-sensor-001-commands', read: true)
          ..add(ResourceType.channel, pattern: 'alerts-.*', write: true);

        var token = await pubnub.grantToken(tokenRequest);
        var parsed = pubnub.parseToken(token.toString());

        expect(parsed.ttl, equals(10080));
        expect(parsed.authorizedUUID, equals('device-sensor-001'));
        expect(parsed.meta['device-type'], equals('temperature-sensor'));
      });
    });
  });
}
