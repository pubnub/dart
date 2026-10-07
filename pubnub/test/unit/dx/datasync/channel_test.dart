import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

const _cursorPage2 = 'eyJpIjoiMzUwMSIsInN2IjpbXX0';

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = newClient();
  });

  group('DataSync [channel] createChannel', () {
    test('POST returns a fully formed channel, no entityClass sent', () async {
      var payload = channelPayload({'department': 'Engineering'});
      when(
        method: 'POST',
        path: dsPath('channels'),
        headers: contentType(channelContentType),
        body: dataBody({
          'id': 'JSchannel-56738',
          'entityClassVersion': 1,
          'status': 'active',
          'payload': payload,
        }),
      ).then(
          status: 200,
          body: dataBody(
              channelObject({'id': 'JSchannel-56738', 'payload': payload})));

      var result = await pubnub.dataSync.createChannel(ChannelInput(
          id: 'JSchannel-56738',
          classVersion: 1,
          status: 'active',
          payload: payload));

      var channel = result.channel;
      expect(channel.id, equals('JSchannel-56738'));
      expect(channel.entityClass, equals('Channel'));
      expect(channel.entityClassVersion, equals(1));
      expect(channel.entityClassLevel, equals('Global'));
      expect(channel.status, equals('active'));
      expect(channel.eTag, equals('y16jaw'));
      expect(channel.expiresAt, equals('2026-10-08T00:00:00Z'));
      expect(channel.payload, equals(payload));
    });

    test('sends an explicit subclass as entityClass and classLevel', () async {
      when(
        method: 'POST',
        path: dsPath('channels'),
        body: dataBody({
          'id': 'channel-1',
          'entityClass': 'PrivateChannel',
          'entityClassVersion': 1,
          'entityClassLevel': 'SubKey',
          'payload': {'firstName': 'Alice'},
        }),
      ).then(
          status: 200,
          body: dataBody(channelObject(
              {'id': 'channel-1', 'entityClass': 'PrivateChannel'})));

      var result = await pubnub.dataSync.createChannel(ChannelInput(
          id: 'channel-1',
          className: 'PrivateChannel',
          classLevel: ClassLevel.subKey,
          classVersion: 1,
          payload: {'firstName': 'Alice'}));

      expect(result.channel.entityClass, equals('PrivateChannel'));
    });

    test('sends classLevel Global and omits id when absent', () async {
      when(
        method: 'POST',
        path: dsPath('channels'),
        body: dataBody({'entityClassVersion': 1, 'entityClassLevel': 'Global'}),
      ).then(status: 200, body: dataBody(channelObject({'id': 'generated-1'})));

      var result = await pubnub.dataSync.createChannel(
          ChannelInput(classVersion: 1, classLevel: ClassLevel.global));

      expect(result.channel.id, equals('generated-1'));
    });
  });

  group('DataSync [channel] getChannel', () {
    test('GET reads the channel back', () async {
      when(method: 'GET', path: dsPath('channels', id: 'channel-1')).then(
          status: 200, body: dataBody(channelObject({'id': 'channel-1'})));

      var result = await pubnub.dataSync.getChannel('channel-1');

      expect(result.channel.id, equals('channel-1'));
      expect(result.channel.status, equals('active'));
    });

    test('rejects with DataSyncException on 404', () async {
      when(method: 'GET', path: dsPath('channels', id: 'channel-1'))
          .then(status: 404, body: body(notFoundError('channel-1')));

      await expectLater(
          pubnub.dataSync.getChannel('channel-1'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0100')));
    });

    test('rejects an empty id', () {
      expect(
          pubnub.dataSync.getChannel(''), throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [channel] setChannel', () {
    var payload =
        channelPayload({'firstName': 'Bianca', 'department': 'Sales'});

    test('PUT full replace; id in the path, entityClass never in the body',
        () async {
      when(
        method: 'PUT',
        path: dsPath('channels', id: 'channel-1'),
        headers: contentType(channelContentType),
        absentHeaders: {'If-Match'},
        body: dataBody({
          'entityClassVersion': 1,
          'status': 'inactive',
          'payload': payload,
        }),
      ).then(
          status: 200,
          body: dataBody(channelObject(
              {'id': 'channel-1', 'status': 'inactive', 'payload': payload})));

      var result = await pubnub.dataSync.setChannel('channel-1',
          ChannelUpdate(classVersion: 1, status: 'inactive', payload: payload));

      expect(result.channel.status, equals('inactive'));
      expect(result.channel.payload, equals(payload));
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PUT',
        path: dsPath('channels', id: 'channel-1'),
        headers: contentType(channelContentType, ifMatch: 'y16jaw'),
        body: dataBody({'entityClassVersion': 1}),
      ).then(status: 200, body: dataBody(channelObject({'id': 'channel-1'})));

      await pubnub.dataSync.setChannel(
          'channel-1', ChannelUpdate(classVersion: 1),
          ifMatchesEtag: 'y16jaw');
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.setChannel('', ChannelUpdate(classVersion: 1)),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [channel] updateChannel', () {
    test('add/replace/remove sends a JSON Patch document', () async {
      when(
        method: 'PATCH',
        path: dsPath('channels', id: 'channel-1'),
        headers: contentType(patchContentType),
        absentHeaders: {'If-Match'},
        body: body([
          {'op': 'add', 'path': '/payload/phone', 'value': '+15550100'},
          {
            'op': 'replace',
            'path': '/payload/email',
            'value': 'updated@acme.test'
          },
          {'op': 'remove', 'path': '/payload/isActive'},
        ]),
      ).then(status: 200, body: dataBody(channelObject({'id': 'channel-1'})));

      await pubnub.dataSync.updateChannel('channel-1',
          add: {'/payload/phone': '+15550100'},
          replace: {'/payload/email': 'updated@acme.test'},
          remove: ['/payload/isActive']);
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'PATCH',
        path: dsPath('channels', id: 'channel-1'),
        headers: contentType(patchContentType, ifMatch: 'y16jaw'),
        body: body([
          {'op': 'replace', 'path': '/payload/firstName', 'value': 'Amelia'}
        ]),
      ).then(status: 200, body: dataBody(channelObject({'id': 'channel-1'})));

      await pubnub.dataSync.updateChannel('channel-1',
          replace: {'/payload/firstName': 'Amelia'}, ifMatchesEtag: 'y16jaw');
    });

    test('supports move / copy / test ops, emitted after add/replace/remove',
        () async {
      when(
        method: 'PATCH',
        path: dsPath('channels', id: 'channel-1'),
        headers: contentType(patchContentType),
        body: body([
          {'op': 'remove', 'path': '/payload/obsolete'},
          {
            'op': 'move',
            'from': '/payload/description',
            'path': '/payload/summary'
          },
          {
            'op': 'copy',
            'from': '/payload/name',
            'path': '/payload/displayName'
          },
          {'op': 'test', 'path': '/payload/kind', 'value': 'public'},
        ]),
      ).then(status: 200, body: dataBody(channelObject({'id': 'channel-1'})));

      await pubnub.dataSync.updateChannel('channel-1', test: {
        '/payload/kind': 'public'
      }, copy: [
        JsonPointerPair(from: '/payload/name', path: '/payload/displayName')
      ], move: [
        JsonPointerPair(from: '/payload/description', path: '/payload/summary')
      ], remove: [
        '/payload/obsolete'
      ]);
    });

    test('rejects when no operation is provided', () {
      expect(pubnub.dataSync.updateChannel('channel-1'),
          throwsA(isA<InvariantException>()));
      expect(
          pubnub.dataSync
              .updateChannel('channel-1', move: [], copy: [], test: {}),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [channel] removeChannel', () {
    test('DELETE replies 200 with an empty body', () async {
      when(
        method: 'DELETE',
        path: dsPath('channels', id: 'channel-1'),
        absentHeaders: {'If-Match'},
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeChannel('channel-1');
    });

    test('forwards ifMatchesEtag as an If-Match header', () async {
      when(
        method: 'DELETE',
        path: dsPath('channels', id: 'channel-1'),
        headers: header('If-Match', 'y16jaw'),
      ).then(status: 200, body: '');

      await pubnub.dataSync.removeChannel('channel-1', ifMatchesEtag: 'y16jaw');
    });

    test('rejects an empty id', () {
      expect(pubnub.dataSync.removeChannel(''),
          throwsA(isA<InvariantException>()));
    });
  });

  group('DataSync [channel] getChannels', () {
    var rows = [
      channelObject({'id': 'channel1'}),
      channelObject({'id': 'c.mem914058452'}),
    ];

    test('sends no query parameters beyond the defaults when called bare',
        () async {
      when(method: 'GET', path: dsPath('channels'))
          .then(status: 200, body: listBody(rows));

      var result = await pubnub.dataSync.getChannels();

      expect(result.channels.map((c) => c.id),
          equals(['channel1', 'c.mem914058452']));
    });

    test('sends limit and surfaces next_cursor', () async {
      when(method: 'GET', path: dsPath('channels', query: {'limit': '10'}))
          .then(
              status: 200,
              body: listBody(rows, nextCursor: _cursorPage2, hasNext: true));

      var result = await pubnub.dataSync.getChannels(limit: 10);

      expect(result.hasNext, isTrue);
      expect(result.nextCursor, equals(_cursorPage2));
    });

    test('maps every optional argument to its query parameter', () async {
      when(
        method: 'GET',
        path: dsPath('channels', query: {
          'entity_class': 'Channel',
          'entity_class_version': '1',
          'entity_class_level': 'Global',
          'cursor': _cursorPage2,
          'limit': '50',
          'filter_fast': 'isActive == true',
          'filter': "(department == 'Engineering') AND (location == 'Pune')",
          'sort': '-createdAt',
        }),
      ).then(status: 200, body: listBody(rows));

      await pubnub.dataSync.getChannels(
          className: 'Channel',
          classVersion: 1,
          classLevel: ClassLevel.global,
          cursor: _cursorPage2,
          limit: 50,
          filterFast: 'isActive == true',
          filter: "(department == 'Engineering') AND (location == 'Pune')",
          sort: '-createdAt');
    });

    test('omits empty string arguments', () async {
      when(method: 'GET', path: dsPath('channels'))
          .then(status: 200, body: listBody(rows));

      await pubnub.dataSync
          .getChannels(className: '', cursor: '', filter: '', sort: '');
    });
  });
}
