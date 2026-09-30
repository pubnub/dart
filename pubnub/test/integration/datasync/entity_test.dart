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

  group('DataSync [entity] lifecycle', () {
    test('create, get, set, update and remove a DartCustomer', () async {
      var id = freshId('dartcustomer');

      var created = await createCustomer(pubnub, cleanup, id);
      expect(created.id, equals(id));
      expect(created.entityClass, equals(customerClass));
      expect(created.entityClassVersion, equals(classVersion));
      expect(created.entityClassLevel, equals('SubKey'));
      expect(created.status, equals('active'));
      expect(created.payload, equals(customerPayload(id)));
      expect(created.eTag, isNotEmpty);
      expect(DateTime.tryParse(created.createdAt!), isNotNull);
      expect(DateTime.tryParse(created.expiresAt!), isNotNull);

      var read = (await pubnub.dataSync.getEntity(id)).entity;
      expect(read.eTag, equals(created.eTag));
      expect(read.payload, equals(created.payload));

      var replaced = (await pubnub.dataSync.setEntity(
              id,
              EntityUpdate(
                  classVersion: classVersion,
                  status: 'inactive',
                  payload: customerPayload(
                      id, {'creditScore': 600, 'city': 'Mumbai'}))))
          .entity;
      expect(replaced.status, equals('inactive'));
      expect(replaced.entityClass, equals(customerClass));
      expect(replaced.payload!['city'], equals('Mumbai'));
      expect(replaced.eTag, isNot(equals(created.eTag)));

      var patched = (await pubnub.dataSync.updateEntity(id,
              replace: {'/payload/creditScore': 810, '/payload/city': 'Goa'},
              remove: ['/payload/email']))
          .entity;
      expect(patched.payload!['creditScore'], equals(810));
      expect(patched.payload!['city'], equals('Goa'));
      expect(patched.payload!.containsKey('email'), isFalse);
      expect(patched.eTag, isNot(equals(replaced.eTag)));
      expect(
          DateTime.parse(patched.updatedAt!)
              .isBefore(DateTime.parse(patched.createdAt!)),
          isFalse);

      var added = (await pubnub.dataSync
              .updateEntity(id, add: {'/payload/email': 'rao@acme.test'}))
          .entity;
      expect(added.payload!['email'], equals('rao@acme.test'));

      await pubnub.dataSync.removeEntity(id);
      await expectLater(
          pubnub.dataSync.getEntity(id), throwsDataSync('DS-0100'));
    });

    test('create without an id returns a server generated id', () async {
      var result = await pubnub.dataSync.createEntity(EntityInput(
          className: customerClass,
          classVersion: classVersion,
          classLevel: ClassLevel.subKey,
          payload: customerPayload('generated')));
      var id = result.entity.id;
      cleanup.add(() => pubnub.dataSync.removeEntity(id));

      expect(id, isNotEmpty);
      expect(result.entity.entityClassLevel, equals('SubKey'));
    });
  });

  group('DataSync [entity] JSON Patch operations', () {
    test('move, copy and test operations are applied in order', () async {
      var id = freshId('dartcustomer');
      await createCustomer(pubnub, cleanup, id);

      var patched = (await pubnub.dataSync.updateEntity(id, move: [
        JsonPointerPair(from: '/payload/email', path: '/payload/private')
      ], copy: [
        JsonPointerPair(from: '/payload/city', path: '/payload/email')
      ], test: {
        '/payload/private': 'alice.verma@acme.test',
        '/payload/email': 'Pune'
      }))
          .entity;

      expect(patched.payload!['private'], equals('alice.verma@acme.test'));
      expect(patched.payload!['email'], equals('Pune'));
      expect(patched.payload!['city'], equals('Pune'));
    });

    test('a failing test operation rejects the whole patch', () async {
      var id = freshId('dartcustomer');
      await createCustomer(pubnub, cleanup, id);

      await expectLater(
          pubnub.dataSync.updateEntity(id,
              replace: {'/payload/city': 'Goa'},
              test: {'/payload/creditScore': 1}),
          throwsA(isA<DataSyncException>()));

      var entity = (await pubnub.dataSync.getEntity(id)).entity;
      expect(entity.payload!['city'], equals('Pune'));
    });
  });

  group('DataSync [entity] optimistic concurrency', () {
    test('writes with the current eTag succeed', () async {
      var id = freshId('dartcustomer');
      var created = await createCustomer(pubnub, cleanup, id);

      var replaced = (await pubnub.dataSync.setEntity(
              id,
              EntityUpdate(
                  classVersion: classVersion,
                  status: 'active',
                  payload: customerPayload(id)),
              ifMatchesEtag: created.eTag))
          .entity;
      var patched = (await pubnub.dataSync.updateEntity(id,
              replace: {'/payload/creditScore': 700},
              ifMatchesEtag: replaced.eTag))
          .entity;
      await pubnub.dataSync.removeEntity(id, ifMatchesEtag: patched.eTag);

      await expectLater(
          pubnub.dataSync.getEntity(id), throwsDataSync('DS-0100'));
    });

    test('writes with a stale eTag fail with DS-0300', () async {
      var id = freshId('dartcustomer');
      await createCustomer(pubnub, cleanup, id);

      await expectLater(
          pubnub.dataSync.setEntity(
              id, EntityUpdate(classVersion: classVersion),
              ifMatchesEtag: 'stale'),
          throwsDataSync('DS-0300'));
      await expectLater(
          pubnub.dataSync.updateEntity(id,
              replace: {'/payload/creditScore': 1}, ifMatchesEtag: 'stale'),
          throwsDataSync('DS-0300'));
      await expectLater(
          pubnub.dataSync.removeEntity(id, ifMatchesEtag: 'stale'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0300')
              .having((e) => e.statusCode, 'statusCode', 412)));

      var entity = (await pubnub.dataSync.getEntity(id)).entity;
      expect(entity.payload!['creditScore'], equals(720));
    });
  });

  group('DataSync [entity] getEntities', () {
    late String marker;
    late List<String> ids;

    setUp(() async {
      marker = runMarker();
      ids = [];
      for (var i = 0; i < 3; i++) {
        var id = freshId('dartcustomer');
        await createCustomer(pubnub, cleanup, id,
            overrides: {'lastName': marker, 'creditScore': 700 + i});
        ids.add(id);
      }
    });

    test('filterFast narrows the listing to the seeded entities', () async {
      var result = await pubnub.dataSync.getEntities(customerClass,
          classVersion: classVersion,
          classLevel: ClassLevel.subKey,
          filterFast: "lastName == '$marker'");

      expect(result.entities.map((e) => e.id), unorderedEquals(ids));
      expect(
          result.entities.every((e) => e.entityClass == customerClass), isTrue);
      // The service does not always send `links`; when it does, it links
      // the current page.
      if (result.links != null) expect(result.links!.self, isNotNull);
    });

    test('pages through the listing with nextCursor', () async {
      var seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        var page = await pubnub.dataSync.getEntities(customerClass,
            filterFast: "lastName == '$marker'", limit: 2, cursor: cursor);
        expect(page.entities.length, lessThanOrEqualTo(2));
        seen.addAll(page.entities.map((e) => e.id));
        cursor = page.hasNext ? page.nextCursor : null;
        pages++;
      } while (cursor != null && pages < 5);

      expect(pages, equals(2));
      expect(seen, unorderedEquals(ids));
      expect(seen.toSet(), hasLength(seen.length));
    });

    test('sort orders the listing', () async {
      var result = await pubnub.dataSync.getEntities(customerClass,
          filterFast: "lastName == '$marker'", sort: 'creditScore:desc');

      expect(result.entities.map((e) => e.payload!['creditScore']),
          equals([702, 701, 700]));
    });

    test('a compound filter with quotes and parentheses is signed correctly',
        () async {
      // The eventually consistent storage may lag behind the writes.
      var found = <String>[];
      for (var attempt = 0; attempt < 5 && found.length < 2; attempt++) {
        if (attempt > 0) await Future<void>.delayed(Duration(seconds: 2));
        var result = await pubnub.dataSync.getEntities(customerClass,
            filter: "(lastName == '$marker') && (creditScore >= 701)");
        found = result.entities.map((e) => e.id).toList();
      }

      expect(found, unorderedEquals(ids.sublist(1)));
    });
  });

  group('DataSync [entity] service errors', () {
    test('an id with an underscore is rejected with DS-0004', () async {
      await expectLater(
          pubnub.dataSync.createEntity(EntityInput(
              id: 'dart_customer',
              className: customerClass,
              classVersion: classVersion,
              payload: customerPayload('dart_customer'))),
          throwsDataSync('DS-0004'));
    });

    test('replacing a missing property is rejected with DS-0006', () async {
      var id = freshId('dartcustomer');
      await createCustomer(pubnub, cleanup, id);

      await expectLater(
          pubnub.dataSync.updateEntity(id, replace: {'/payload/nosuch': 1}),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0006')
              .having((e) => e.path, 'path', '/payload/nosuch')));
    });

    test('an unparsable filter is rejected with DS-1000', () async {
      await expectLater(
          pubnub.dataSync
              .getEntities(customerClass, filterFast: "lastName == 'a' AND"),
          throwsDataSync('DS-1000'));
    });

    test('removing an entity twice fails with DS-0100', () async {
      var id = freshId('dartcustomer');
      await createCustomer(pubnub, cleanup, id);
      await pubnub.dataSync.removeEntity(id);

      await expectLater(
          pubnub.dataSync.removeEntity(id), throwsDataSync('DS-0100'));
    });
  });
}
