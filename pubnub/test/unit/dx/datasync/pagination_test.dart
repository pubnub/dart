import 'dart:convert';

import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

/// Uniform view over the result of a DataSync list endpoint.
class _Page {
  final List<String> ids;
  final DataSyncPage? page;
  final bool hasNext;
  final String? nextCursor;
  final DataSyncLinks? links;

  _Page(this.ids, this.page, this.hasNext, this.nextCursor, this.links);
}

class _ListEndpoint {
  final String name;
  final String resource;
  final Map<String, String> query;
  final Map<String, dynamic> Function(String id) row;
  final Future<_Page> Function(PubNub pubnub, {String? cursor, int? limit})
      call;

  _ListEndpoint(this.name, this.resource, this.query, this.row, this.call);
}

final _endpoints = [
  _ListEndpoint('getEntities', 'entities', {'entity_class': 'Customer'},
      (id) => entityObject({'id': id}), (pubnub, {cursor, limit}) async {
    var r = await pubnub.dataSync
        .getEntities('Customer', cursor: cursor, limit: limit);
    return _Page(r.entities.map((e) => e.id).toList(), r.page, r.hasNext,
        r.nextCursor, r.links);
  }),
  _ListEndpoint(
      'getRelationships',
      'relationships',
      {'relationship_class': 'REQUESTED_BY'},
      (id) => relationshipObject({'id': id}), (pubnub, {cursor, limit}) async {
    var r = await pubnub.dataSync
        .getRelationships('REQUESTED_BY', cursor: cursor, limit: limit);
    return _Page(r.relationships.map((e) => e.id).toList(), r.page, r.hasNext,
        r.nextCursor, r.links);
  }),
  _ListEndpoint('getUsers', 'users', {}, (id) => userObject({'id': id}),
      (pubnub, {cursor, limit}) async {
    var r = await pubnub.dataSync.getUsers(cursor: cursor, limit: limit);
    return _Page(r.users.map((e) => e.id).toList(), r.page, r.hasNext,
        r.nextCursor, r.links);
  }),
  _ListEndpoint(
      'getChannels', 'channels', {}, (id) => channelObject({'id': id}), (pubnub,
          {cursor, limit}) async {
    var r = await pubnub.dataSync.getChannels(cursor: cursor, limit: limit);
    return _Page(r.channels.map((e) => e.id).toList(), r.page, r.hasNext,
        r.nextCursor, r.links);
  }),
  _ListEndpoint(
      'getMemberships', 'memberships', {}, (id) => membershipObject({'id': id}),
      (pubnub, {cursor, limit}) async {
    var r = await pubnub.dataSync.getMemberships(cursor: cursor, limit: limit);
    return _Page(r.memberships.map((e) => e.id).toList(), r.page, r.hasNext,
        r.nextCursor, r.links);
  }),
];

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = newClient();
  });

  for (var endpoint in _endpoints) {
    group('DataSync pagination [${endpoint.name}]', () {
      void mock(String responseBody, {Map<String, String> query = const {}}) {
        when(
          method: 'GET',
          path: dsPath(endpoint.resource, query: {...endpoint.query, ...query}),
        ).then(status: 200, body: responseBody);
      }

      test('surfaces every meta field', () async {
        mock(jsonEncode({
          'data': [endpoint.row('a')],
          'links': {'self': '/self', 'next': '/next'},
          'meta': {'next_cursor': 'TjQw', 'has_next': true, 'limit': 20},
        }));

        var page = await endpoint.call(pubnub);

        expect(page.ids, equals(['a']));
        expect(page.page!.nextCursor, equals('TjQw'));
        expect(page.page!.hasNext, isTrue);
        expect(page.page!.limit, equals(20));
        expect(page.hasNext, isTrue);
        expect(page.nextCursor, equals('TjQw'));
      });

      test('surfaces links, including extra links the service adds', () async {
        var links = {
          'self': '/v1/datasync/subkeys/test/${endpoint.resource}?limit=20',
          'next': '/v1/datasync/subkeys/test/${endpoint.resource}?cursor=TjQw',
          'entityClass': '/v1/datasync/subkeys/test/entity-classes/Customer',
        };
        mock(jsonEncode({
          'data': [endpoint.row('a')],
          'links': links,
          'meta': {'next_cursor': 'TjQw', 'has_next': true},
        }));

        var page = await endpoint.call(pubnub);

        expect(page.links!.self, equals(links['self']));
        expect(page.links!.next, equals(links['next']));
        expect(page.links!['entityClass'], equals(links['entityClass']));
        expect(page.links!['missing'], isNull);
        expect(page.links!.all, equals(links));
      });

      test('keeps a last-page null next link as null', () async {
        mock(jsonEncode({
          'data': [],
          'links': {'self': '/self', 'next': null},
          'meta': {'has_next': false},
        }));

        var page = await endpoint.call(pubnub);

        expect(page.links!.self, equals('/self'));
        expect(page.links!.next, isNull);
        expect(page.links!.all.containsKey('next'), isTrue);
      });

      test('keeps last-page null cursors as null', () async {
        mock(jsonEncode({
          'data': [],
          'links': {'self': '/self', 'next': null},
          'meta': {'next_cursor': null, 'has_next': false, 'limit': 20},
        }));

        var page = await endpoint.call(pubnub);

        expect(page.ids, isEmpty);
        expect(page.nextCursor, isNull);
        expect(page.hasNext, isFalse);
      });

      test('accepts the spec-minimal meta (has_next only)', () async {
        mock(jsonEncode({
          'data': [endpoint.row('a')],
          'meta': {'has_next': true},
        }));

        var page = await endpoint.call(pubnub);

        expect(page.hasNext, isTrue);
        expect(page.nextCursor, isNull);
        expect(page.page!.limit, isNull);
      });

      test('accepts an envelope without meta', () async {
        mock(jsonEncode({
          'data': [endpoint.row('a')]
        }));

        var page = await endpoint.call(pubnub);

        expect(page.ids, equals(['a']));
        expect(page.links, isNull);
        expect(page.page, isNull);
        expect(page.hasNext, isFalse);
        expect(page.nextCursor, isNull);
      });

      test('rejects rows that are not a list as a malformed response',
          () async {
        mock(jsonEncode({'data': 'oops'}));

        await expectLater(
            endpoint.call(pubnub), throwsA(isA<MalformedResponseException>()));
      });

      test('accepts an envelope without data', () async {
        mock(jsonEncode({
          'meta': {'has_next': false}
        }));

        var page = await endpoint.call(pubnub);

        expect(page.ids, isEmpty);
      });

      test('ignores unknown keys in rows and meta', () async {
        mock(jsonEncode({
          'data': [
            {...endpoint.row('a'), 'futureField': 1}
          ],
          'meta': {'has_next': false, 'total': 7},
        }));

        var page = await endpoint.call(pubnub);

        expect(page.ids, equals(['a']));
      });

      test('sends next_cursor back as the cursor query parameter', () async {
        mock(
            jsonEncode({
              'data': [endpoint.row('a'), endpoint.row('b')],
              'meta': {'next_cursor': 'TjIw', 'has_next': true, 'limit': 2},
            }),
            query: {'limit': '2'});
        mock(
            jsonEncode({
              'data': [endpoint.row('c')],
              'meta': {'next_cursor': null, 'has_next': false, 'limit': 2},
            }),
            query: {'limit': '2', 'cursor': 'TjIw'});

        var ids = <String>[];
        String? cursor;
        var pages = 0;
        do {
          var page = await endpoint.call(pubnub, cursor: cursor, limit: 2);
          ids.addAll(page.ids);
          cursor = page.hasNext ? page.nextCursor : null;
          pages++;
        } while (cursor != null && pages < 5);

        expect(pages, equals(2));
        expect(ids, equals(['a', 'b', 'c']));
      });
    });
  }
}
