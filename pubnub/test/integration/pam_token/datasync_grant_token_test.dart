@TestOn('vm')
@Tags(['integration'])

import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';

import '_pam_client.dart';

/// Finds the resource granted to [name] for [type], or `null` when absent.
Resource? resourceNamed(
        List<Resource> resources, ResourceType type, String name) =>
    resources.cast<Resource?>().firstWhere(
        (resource) => resource!.type == type && resource.name == name,
        orElse: () => null);

/// Finds the pattern granted to [pattern] for [type], or `null` when absent.
Resource? patternNamed(
        List<Resource> patterns, ResourceType type, String pattern) =>
    patterns.cast<Resource?>().firstWhere(
        (resource) => resource!.type == type && resource.pattern == pattern,
        orElse: () => null);

void main() {
  late PubNub pubnub;

  group('Integration [PAM grantToken DataSync]', () {
    setUp(() {
      pubnub = createPamClient();
    });

    test('grants and parses DataSync entity, relationship and membership',
        () async {
      var request = pubnub.requestToken(ttl: 60)
        ..add(ResourceType.entity, name: 'school-greenwood-001', get: true)
        ..add(ResourceType.relationship,
            name: 'student-alice-042:school-greenwood-001', get: true)
        ..add(ResourceType.membership,
            name: 'user-alice-042:channel-engineering-001',
            get: true,
            update: true);

      var token =
          pubnub.parseToken((await pubnub.grantToken(request)).toString());

      var entity = resourceNamed(
          token.resources, ResourceType.entity, 'school-greenwood-001');
      expect(entity, isNotNull);
      expect(entity!.get, isTrue);
      expect(entity.update, isFalse);
      expect(entity.create, isFalse);
      expect(entity.delete, isFalse);

      var relationship = resourceNamed(token.resources,
          ResourceType.relationship, 'student-alice-042:school-greenwood-001');
      expect(relationship, isNotNull);
      expect(relationship!.get, isTrue);
      expect(relationship.update, isFalse);

      var membership = resourceNamed(token.resources, ResourceType.membership,
          'user-alice-042:channel-engineering-001');
      expect(membership, isNotNull);
      expect(membership!.get, isTrue);
      expect(membership.update, isTrue);
      expect(membership.create, isFalse);
      expect(membership.delete, isFalse);
    });

    test('grants and parses DataSync entity patterns', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..add(ResourceType.entity,
            pattern: 'human-*',
            create: true,
            get: true,
            update: true,
            delete: true);

      var token =
          pubnub.parseToken((await pubnub.grantToken(request)).toString());

      var pattern =
          patternNamed(token.patterns, ResourceType.entity, 'human-*');
      expect(pattern, isNotNull);
      expect(pattern!.bit, equals(120));
      expect(pattern.create, isTrue);
      expect(pattern.get, isTrue);
      expect(pattern.update, isTrue);
      expect(pattern.delete, isTrue);

      // Patterns must not leak into the exact-match resources.
      expect(resourceNamed(token.resources, ResourceType.entity, 'human-*'),
          isNull);
    });

    test('grants and parses the users scope', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..add(ResourceType.user,
            name: 'user-alice-042',
            create: true,
            get: true,
            update: true,
            delete: true);

      var token =
          pubnub.parseToken((await pubnub.grantToken(request)).toString());

      var user =
          resourceNamed(token.resources, ResourceType.user, 'user-alice-042');
      expect(user, isNotNull);
      expect(user!.create, isTrue);
      expect(user.get, isTrue);
      expect(user.update, isTrue);
      expect(user.delete, isTrue);
    });

    test('users scope is distinct from the uuids scope', () async {
      var request = pubnub.requestToken(ttl: 60)
        ..add(ResourceType.user, name: 'user-alice-042', get: true);

      var token =
          pubnub.parseToken((await pubnub.grantToken(request)).toString());

      expect(
          resourceNamed(token.resources, ResourceType.user, 'user-alice-042'),
          isNotNull);
      expect(
          token.resources.where((r) => r.type == ResourceType.uuid), isEmpty);
    });

    test('grants and parses DataSync projections alongside user metadata',
        () async {
      var request = pubnub.requestToken(ttl: 60, meta: {'tenant': 'acme'})
        ..add(ResourceType.channel, name: 'channel-engineering-001', read: true)
        ..add(ResourceType.entity, name: 'user.A', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            name: 'user.A', projection: 'proj1')
        ..addDataSyncProjection(ResourceType.membership,
            pattern: 'user.*', projection: defaultProjection);

      var token =
          pubnub.parseToken((await pubnub.grantToken(request)).toString());

      expect(token.projections, hasLength(2));

      var entityProjection = token.projections
          .firstWhere((projection) => projection.type == ResourceType.entity);
      expect(entityProjection.name, equals('user.A'));
      expect(entityProjection.pattern, isNull);
      expect(entityProjection.projection, equals('proj1'));

      var membershipProjection = token.projections.firstWhere(
          (projection) => projection.type == ResourceType.membership);
      expect(membershipProjection.pattern, equals('user.*'));
      expect(membershipProjection.name, isNull);
      expect(membershipProjection.projection, equals(defaultProjection));

      // User supplied metadata survives alongside the encoded projections.
      expect(token.meta['tenant'], equals('acme'));
      expect(token.meta['pn-projections'], isNotNull);
    });

    test('grants classic, users and DataSync scopes in a single request',
        () async {
      var request = pubnub.requestToken(
          ttl: 60, authorizedUserId: 'dataSync-tester')
        ..add(ResourceType.channel,
            name: 'channel-engineering-001', read: true, write: true)
        ..add(ResourceType.channelGroup, name: 'group-engineering', read: true)
        ..add(ResourceType.user, name: 'user-alice-042', get: true)
        ..add(ResourceType.entity, name: 'school-greenwood-001', get: true)
        ..add(ResourceType.relationship,
            name: 'student-alice-042:school-greenwood-001', get: true)
        ..add(ResourceType.membership,
            name: 'user-alice-042:channel-engineering-001', get: true);

      var token =
          pubnub.parseToken((await pubnub.grantToken(request)).toString());

      expect(token.authorizedUUID, equals('dataSync-tester'));

      for (var type in [
        ResourceType.channel,
        ResourceType.channelGroup,
        ResourceType.user,
        ResourceType.entity,
        ResourceType.relationship,
        ResourceType.membership
      ]) {
        expect(token.resources.where((r) => r.type == type), isNotEmpty,
            reason: 'expected a $type resource in the parsed token');
      }
    });

    group('local validation', () {
      // The server rejects such grants with "This grant contains no
      // permissions", so they are rejected before being sent.
      test('rejects a grant carrying only projections', () {
        var request = pubnub.requestToken(ttl: 60)
          ..addDataSyncProjection(ResourceType.entity,
              name: 'user.A', projection: 'proj1');

        expect(pubnub.grantToken(request), throwsA(isA<InvariantException>()));
      });

      test('rejects mixing the user and uuid scopes', () {
        var request = pubnub.requestToken(ttl: 60)
          ..add(ResourceType.user, name: 'user-alice-042', get: true)
          ..add(ResourceType.uuid, name: 'uuid-alice-042', get: true);

        expect(pubnub.grantToken(request), throwsA(isA<InvariantException>()));
      });

      test('rejects mixing the space and channel scopes', () {
        var request = pubnub.requestToken(ttl: 60)
          ..add(ResourceType.space, name: 'space-lobby', read: true)
          ..add(ResourceType.channel, name: 'channel-lobby', read: true);

        expect(pubnub.grantToken(request), throwsA(isA<InvariantException>()));
      });

      test('rejects projections on non DataSync resource types', () {
        var request = pubnub.requestToken(ttl: 60);

        expect(
            // `channel` supports projections (`datasync:channels`), so the
            // scopes without a projection scope are used here.
            () => request.addDataSyncProjection(ResourceType.uuid,
                name: 'uuid-lobby', projection: 'proj1'),
            throwsA(isA<InvariantException>()));
      });

      test('rejects a projection with both a name and a pattern', () {
        var request = pubnub.requestToken(ttl: 60);

        expect(
            () => request.addDataSyncProjection(ResourceType.entity,
                name: 'user.A', pattern: 'user.*', projection: 'proj1'),
            throwsA(isA<InvariantException>()));
      });
    });
  });
}
