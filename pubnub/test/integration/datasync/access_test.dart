@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

const _customerSecret = 'customer-private-value';
const _loanQuoteSecret = 'loanquote-private-value';

// Payload fields of each projection, see the `projections` test suite of
// the JavaScript SDK.
const _loanQuoteDefaultFields = ['make', 'model', 'price', 'quoteId'];
const _loanQuoteAdminFields = ['private', 'quoteId'];

void _expectFields(Map<String, dynamic>? payload, List<String> fields) =>
    expect(payload!.keys.toList()..sort(), equals(fields));

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;
  late List<PubNub> readers;

  setUp(() {
    pubnub = superClient();
    cleanup = Cleanup();
    readers = [];
  });

  tearDown(() async {
    await cleanup.run();
    for (var reader in readers) {
      await reader.unsubscribeAll();
    }
  });

  Future<PubNub> reader(void Function(TokenRequest) grant) async {
    var request = pubnub.requestToken(ttl: 5);
    grant(request);
    var token = await pubnub.grantToken(request);
    var client = readerClient(freshId('dartreader'), token.toString());
    readers.add(client);
    return client;
  }

  group('DataSync [access] token permissions', () {
    test('a get-only grant reads but cannot remove', () async {
      var id = freshId('dartcustomer');
      await createCustomer(pubnub, cleanup, id);

      var client = await reader((request) => request.add(ResourceType.entity,
          pattern: 'dartcustomer-.*', get: true));

      expect((await client.dataSync.getEntity(id)).entity.id, equals(id));
      await expectLater(
          client.dataSync.removeEntity(id), throwsA(isA<PubNubException>()));
      expect((await pubnub.dataSync.getEntity(id)).entity.id, equals(id));
    });

    test('a grant does not reach entities outside its pattern', () async {
      var id = freshId('dartcustomer');
      await createCustomer(pubnub, cleanup, id);

      var client = await reader((request) => request.add(ResourceType.entity,
          pattern: 'dartloanquote-.*', get: true));

      await expectLater(
          client.dataSync.getEntity(id), throwsA(isA<PubNubException>()));
    });
  });

  group('DataSync [access] grantToken encodes projections', () {
    test('resource and pattern assignments round-trip for every type',
        () async {
      var token = await pubnub.grantToken(pubnub.requestToken(ttl: 5)
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            name: 'dartcustomer-1', projection: 'admin')
        ..addDataSyncProjection(ResourceType.entity,
            pattern: 'dartcustomer-.*', projection: 'admin')
        ..addDataSyncProjection(ResourceType.relationship,
            pattern: 'dartrequestedby-.*', projection: 'admin')
        ..addDataSyncProjection(ResourceType.user,
            name: 'dartuser-1', projection: defaultProjection)
        ..addDataSyncProjection(ResourceType.channel,
            pattern: 'dartchannel-.*', projection: defaultProjection)
        ..addDataSyncProjection(ResourceType.membership,
            pattern: 'dartuser-.*:dartchannel-.*',
            projection: defaultProjection));

      var parsed = pubnub.parseToken(token.toString());

      expect(
          parsed.meta['pn-projections'],
          equals({
            'res': {
              'datasync:entities:dartcustomer-1': 'admin',
              'datasync:users:dartuser-1': '__default__',
            },
            'pat': {
              'datasync:entities:dartcustomer-.*': 'admin',
              'datasync:relationships:dartrequestedby-.*': 'admin',
              'datasync:channels:dartchannel-.*': '__default__',
              'datasync:memberships:dartuser-.*:dartchannel-.*': '__default__',
            },
          }));
      expect(
          parsed.projections
              .map((p) => [p.type, p.name ?? p.pattern, p.projection]),
          unorderedEquals([
            [ResourceType.entity, 'dartcustomer-1', 'admin'],
            [ResourceType.user, 'dartuser-1', '__default__'],
            [ResourceType.entity, 'dartcustomer-.*', 'admin'],
            [ResourceType.relationship, 'dartrequestedby-.*', 'admin'],
            [ResourceType.channel, 'dartchannel-.*', '__default__'],
            [
              ResourceType.membership,
              'dartuser-.*:dartchannel-.*',
              '__default__'
            ],
          ]));
    });

    test('a token without projections carries no pn-projections', () async {
      var token = await pubnub.grantToken(pubnub.requestToken(ttl: 5)
        ..add(ResourceType.entity, pattern: '.*', get: true));

      var parsed = pubnub.parseToken(token.toString());
      expect(parsed.projections, isEmpty);
      expect((parsed.meta as Map?)?['pn-projections'], isNull);
    });
  });

  group('DataSync [access] REST reads are projected by the token', () {
    late String customerId;
    late String loanQuoteId;

    setUp(() async {
      customerId = freshId('dartcustomer');
      loanQuoteId = freshId('dartloanquote');
      await createCustomer(pubnub, cleanup, customerId,
          overrides: {'private': _customerSecret});
      await pubnub.dataSync.createEntity(EntityInput(
          id: loanQuoteId,
          className: loanQuoteClass,
          classVersion: classVersion,
          status: 'active',
          payload:
              loanQuotePayload(loanQuoteId, {'private': _loanQuoteSecret})));
      cleanup.add(() => pubnub.dataSync.removeEntity(loanQuoteId));
    });

    void grantAll(TokenRequest request) =>
        request.add(ResourceType.entity, pattern: '.*', get: true);

    test('without an assignment the __default__ view withholds private',
        () async {
      var client = await reader(grantAll);

      var entity = (await client.dataSync.getEntity(customerId)).entity;
      _expectFields(entity.payload, customerDefaultFields);

      var full = (await pubnub.dataSync.getEntity(customerId)).entity;
      expect(full.payload!['private'], equals(_customerSecret));
    });

    test('a pattern assigned admin exposes private and drops email', () async {
      var client = await reader((request) => request
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            pattern: 'dartcustomer-.*', projection: 'admin'));

      var entity = (await client.dataSync.getEntity(customerId)).entity;
      _expectFields(entity.payload, customerAdminFields);
      expect(entity.payload!['private'], equals(_customerSecret));
    });

    test('an exact resource assignment selects admin for that id only',
        () async {
      var client = await reader((request) => request
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            name: customerId, projection: 'admin'));

      _expectFields(
          (await client.dataSync.getEntity(customerId)).entity.payload,
          customerAdminFields);
      _expectFields(
          (await client.dataSync.getEntity(loanQuoteId)).entity.payload,
          _loanQuoteDefaultFields);
    });

    test('an explicit __default__ behaves like no assignment', () async {
      var client = await reader((request) => request
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            pattern: '.*', projection: defaultProjection));

      _expectFields(
          (await client.dataSync.getEntity(customerId)).entity.payload,
          customerDefaultFields);
    });

    test('list reads are projected too', () async {
      var client = await reader((request) => request
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            pattern: 'dartcustomer-.*', projection: 'admin'));

      var result = await client.dataSync.getEntities(customerClass,
          filterFast: "customerId == '$customerId'");
      _expectFields(result.entities.single.payload, customerAdminFields);
    });

    test('LoanQuote admin narrows the payload to quoteId and private',
        () async {
      var client = await reader((request) => request
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            pattern: 'dartloanquote-.*', projection: 'admin'));

      var entity = (await client.dataSync.getEntity(loanQuoteId)).entity;
      _expectFields(entity.payload, _loanQuoteAdminFields);
      expect(entity.payload!['private'], equals(_loanQuoteSecret));
    });

    test('an unknown projection name rejects the read with DS-0202', () async {
      var client = await reader((request) => request
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            pattern: '.*', projection: 'nosuchprojection'));

      await expectLater(
          client.dataSync.getEntity(customerId), throwsDataSync('DS-0202'));
    });

    test('__admin__ is not a projection name, the name is admin', () async {
      var client = await reader((request) => request
        ..add(ResourceType.entity, pattern: '.*', get: true)
        ..addDataSyncProjection(ResourceType.entity,
            pattern: '.*', projection: '__admin__'));

      await expectLater(
          client.dataSync.getEntity(customerId), throwsDataSync('DS-0202'));
    });
  });
}
