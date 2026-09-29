import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

import '../net/fake_net.dart';

part 'fixtures/wire_events.dart';

final _keyset =
    Keyset(subscribeKey: 'demo', publishKey: 'demo', userId: UserId('test'));

Envelope _envelope(String wire, {Map<String, dynamic>? patch}) =>
    Envelope.fromJson(<String, dynamic>{
      ...json.decode(wire) as Map<String, dynamic>,
      ...?patch
    });

SubscriptionEvent? _event(String wire, {Map<String, dynamic>? patch}) =>
    SubscriptionEvent.fromEnvelope(_envelope(wire, patch: patch), _keyset);

/// Envelope patch that replaces the `d` payload with [payload].
Map<String, dynamic> _withPayload(dynamic payload) => {'d': payload};

void main() {
  group('MessageType', () {
    test('maps wire `e` values', () {
      expect(MessageTypeExtension.fromInt(null), equals(MessageType.normal));
      expect(MessageTypeExtension.fromInt(0), equals(MessageType.normal));
      expect(MessageTypeExtension.fromInt(1), equals(MessageType.signal));
      expect(MessageTypeExtension.fromInt(2), equals(MessageType.objects));
      expect(
          MessageTypeExtension.fromInt(3), equals(MessageType.messageAction));
      expect(MessageTypeExtension.fromInt(4), equals(MessageType.file));
      expect(MessageTypeExtension.fromInt(5), equals(MessageType.dataSync));
    });

    test('maps unrecognized `e` values to unknown', () {
      expect(MessageTypeExtension.fromInt(6), equals(MessageType.unknown));
      expect(MessageTypeExtension.fromInt(99), equals(MessageType.unknown));
    });

    test('toInt round trips known types', () {
      for (var type
          in MessageType.values.where((t) => t != MessageType.unknown)) {
        expect(MessageTypeExtension.fromInt(type.toInt()), equals(type));
      }
      expect(MessageType.unknown.toInt(), equals(-1));
    });
  });

  group('SubscriptionEvent.fromEnvelope', () {
    test('message', () {
      var event = _event(_message);
      expect(event, isA<MessageEvent>());
      event as MessageEvent;
      expect(event.message, equals({'text': 'hello'}));
      expect(event.publisher, equals(UUID('probe-user-32499')));
      expect(event.userMeta, equals({'m': 1}));
      expect(event.customMessageType, equals('chat-msg'));
      expect(event.error, isNull);
      expect(event.channel, equals('ch'));
      expect(event.subscription, equals('ch'));
      expect(event.timetoken,
          equals(Timetoken(BigInt.parse('17905741246383965'))));
    });

    test('message with explicit `e: 0`', () {
      expect(_event(_message, patch: {'e': 0}), isA<MessageEvent>());
    });

    test('signal', () {
      var event = _event(_signal);
      expect(event, isA<SignalEvent>());
      event as SignalEvent;
      expect(event.message, equals('typing'));
      expect(event.publisher, equals(UUID('probe-user-32499')));
      expect(event.customMessageType, equals('typing-sig'));
      expect(event.channel, equals('ch'));
    });

    test('message action added', () {
      var event = _event(_messageActionAdded);
      expect(event, isA<MessageActionEvent>());
      event as MessageActionEvent;
      expect(event.event, equals(MessageActionEventType.added));
      expect(event.action.type, equals('reaction'));
      expect(event.action.value, equals('smile'));
      expect(event.action.uuid, equals('probe-user-32499'));
      expect(event.action.actionTimetoken, equals('17905741248321456'));
      expect(event.action.messageTimetoken, equals('17905741246383965'));
      expect(event.actionTimetoken,
          equals(Timetoken(BigInt.parse('17905741248321456'))));
      expect(event.messageTimetoken,
          equals(Timetoken(BigInt.parse('17905741246383965'))));
    });

    test('message action removed', () {
      var event = _event(_messageActionRemoved) as MessageActionEvent;
      expect(event.event, equals(MessageActionEventType.removed));
      expect(event.action.value, equals('x'));
      expect(event.action.uuid, equals('probe-user-11266'));
    });

    test('message action with unrecognized event', () {
      var wire = json.decode(_messageActionAdded) as Map<String, dynamic>;
      var event = _event(_messageActionAdded,
          patch: _withPayload(<String, dynamic>{
            ...wire['d'] as Map<String, dynamic>,
            'event': 'edited'
          })) as MessageActionEvent;
      expect(event.event, equals(MessageActionEventType.unknown));
    });

    test('file', () {
      var event = _event(_file);
      expect(event, isA<FileEvent>());
      event as FileEvent;
      expect(event.file!.id, equals('abc-123'));
      expect(event.file!.name, equals('cat.png'));
      expect(event.message, equals({'note': 'pic'}));
      expect(event.publisher, equals(UUID('probe-user-32499')));
      expect(event.customMessageType, equals('file-msg'));
      expect(event.error, isNull);
    });

    test('file url matches FileDx.getFileUrl', () {
      var pubnub = PubNub(defaultKeyset: _keyset);
      var event = _event(_file) as FileEvent;
      expect(event.url,
          equals(pubnub.files.getFileUrl('ch', 'abc-123', 'cat.png')));
    });

    test('file that failed to decrypt', () {
      var error = PubNubException('Can not decrypt the message payload.');
      var event =
          _event(_file, patch: {'d': 'bm90IGRlY3J5cHRhYmxl', 'error': error})
              as FileEvent;
      expect(event.file, isNull);
      expect(event.url, isNull);
      expect(event.message, isNull);
      expect(event.error, same(error));
    });

    test('objects channel set', () {
      var event = _event(_objectsChannelSet);
      expect(event, isA<ChannelMetadataEvent>());
      event as ChannelMetadataEvent;
      expect(event.event, equals(ObjectsEventType.set));
      expect(event.metadata.id, equals('ch'));
      expect(event.metadata.name, equals('Probe Chan'));
      expect(event.metadata.description, equals('d'));
      expect(event.metadata.custom, equals({'k': 'v'}));
      expect(event.metadata.eTag, equals('9fa5cdad728e8e80118ac14e357bdd48'));
      expect(event.metadata.updated, equals('2026-09-28T05:42:05.461456Z'));
    });

    test('objects channel delete', () {
      var event = _event(_objectsChannelDelete) as ChannelMetadataEvent;
      expect(event.event, equals(ObjectsEventType.delete));
      expect(event.metadata.id, equals('ch'));
      expect(event.metadata.name, isNull);
      expect(event.metadata.eTag, isNull);
    });

    test('objects uuid set', () {
      var event = _event(_objectsUuidSet);
      expect(event, isA<UuidMetadataEvent>());
      event as UuidMetadataEvent;
      expect(event.event, equals(ObjectsEventType.set));
      expect(event.metadata.id, equals('ch'));
      expect(event.metadata.name, equals('Probe User'));
      expect(event.metadata.custom, equals({'a': 1}));
      expect(event.metadata.eTag, equals('ab9e625153f1bacc28508d28b6a22089'));
    });

    test('objects uuid delete', () {
      var event = _event(_objectsUuidDelete) as UuidMetadataEvent;
      expect(event.event, equals(ObjectsEventType.delete));
      expect(event.metadata.id, equals('ch'));
      expect(event.metadata.name, isNull);
    });

    test('objects membership set', () {
      var event = _event(_objectsMembershipSet);
      expect(event, isA<MembershipMetadataEvent>());
      event as MembershipMetadataEvent;
      expect(event.event, equals(ObjectsEventType.set));
      expect(event.channelId, equals('ch'));
      expect(event.uuid, equals('probe-user-32499'));
      expect(event.custom, equals({'role': 'admin'}));
      expect(event.eTag, equals('Acr+lIO/3JX93wE'));
      expect(event.updated, equals('2026-09-28T05:42:06.651180671Z'));
    });

    test('objects membership delete', () {
      var event = _event(_objectsMembershipDelete) as MembershipMetadataEvent;
      expect(event.event, equals(ObjectsEventType.delete));
      expect(event.channelId, equals('ch'));
      expect(event.uuid, equals('probe-user-11266'));
      expect(event.custom, isNull);
    });

    test('DataSync entity create', () {
      var event = _event(_dataSyncEntityCreate);
      expect(event, isA<DataSyncEvent>());
      event as DataSyncEvent;
      expect(event.event, equals(DataSyncEventType.create));
      expect(event.objectType, equals(DataSyncObjectType.entity));
      expect(event.className, equals('JSCustomer'));
      expect(event.classVersion, equals(1));
      expect(event.classLevel, equals('SubKey'));
      expect(event.source, equals('data-sync'));
      expect(event.version, equals('1.0'));
      expect(event.id, equals('dartcustomer.40601'));
      expect(event.eTag, equals('3w5e111z2x3lk'));
      expect(event.createdAt, equals('2026-09-28T05:55:55.583771Z'));
      expect(event.updatedAt, equals('2026-09-28T05:55:55.583771Z'));
      expect(event.expiresAt, equals('2027-09-29T00:00:00Z'));
      expect(event.deletedAt, isNull);
      expect(event.payload!['creditScore'], equals(700));
    });

    test('DataSync entity update', () {
      var event = _event(_dataSyncEntityUpdate) as DataSyncEvent;
      expect(event.event, equals(DataSyncEventType.update));
      expect(event.eTag, equals('3w5e111z2x54m'));
      expect(event.payload!['creditScore'], equals(710));
    });

    test('DataSync entity delete', () {
      var event = _event(_dataSyncEntityDelete) as DataSyncEvent;
      expect(event.event, equals(DataSyncEventType.delete));
      expect(event.objectType, equals(DataSyncObjectType.entity));
      expect(event.id, equals('dartcustomer.40601'));
      expect(event.deletedAt, equals('2026-09-28T05:56:25.631142Z'));
      expect(event.payload, isNull);
      expect(event.eTag, isNull);
    });

    test('DataSync user create', () {
      var event = _event(_dataSyncUserCreate) as DataSyncEvent;
      expect(event.objectType, equals(DataSyncObjectType.user));
      expect(event.className, equals('User'));
      expect(event.classLevel, equals('Global'));
      expect(event.payload, equals({'name': 'U'}));
    });

    test('DataSync channel delete', () {
      var event = _event(_dataSyncChannelDelete) as DataSyncEvent;
      expect(event.event, equals(DataSyncEventType.delete));
      expect(event.objectType, equals(DataSyncObjectType.channel));
      expect(event.id, equals('dartcap.chan40601'));
    });

    test('DataSync membership update', () {
      var event = _event(_dataSyncMembershipUpdate) as DataSyncEvent;
      expect(event.event, equals(DataSyncEventType.update));
      expect(event.objectType, equals(DataSyncObjectType.membership));
      expect(event.channelId, equals('dartcap.chan40601'));
      expect(event.userId, equals('dartcap.user40601'));
      expect(event.payload, equals({'role': 'owner'}));
    });

    test('presence join', () {
      var event = _event(_presenceJoin);
      expect(event, isA<PresenceEvent>());
      event as PresenceEvent;
      expect(event.action, equals(PresenceAction.join));
      expect(event.uuid, equals(UUID('listener')));
      expect(event.occupancy, equals(1));
      expect(event.channel, equals('ch'));
      expect(event.subscription, equals('ch'));
      expect(event.envelope.channel, equals('ch-pnpres'));
    });

    test('presence state change', () {
      var event = _event(_presenceStateChange) as PresenceEvent;
      expect(event.action, equals(PresenceAction.stateChange));
      expect(event.uuid, equals(UUID('probe-user-11266')));
      expect(event.state, equals({'mood': 'ok'}));
      expect(event.occupancy, equals(2));
    });

    test('presence interval', () {
      var event = _event(_presenceInterval) as PresenceEvent;
      expect(event.action, equals(PresenceAction.interval));
      expect(event.uuid, isNull);
      expect(event.occupancy, equals(3));
      expect(event.join, equals([UUID('u1'), UUID('u2')]));
      expect(event.leave, equals([UUID('u3')]));
      expect(event.timeout, equals([UUID('u4')]));
      expect(event.hereNowRefresh, isFalse);
    });

    test('discards events of unknown type', () {
      expect(_envelope(_unknownType).messageType, equals(MessageType.unknown));
      expect(_event(_unknownType), isNull);
    });

    group('discards malformed events', () {
      test('objects without type', () {
        expect(
            _event(_objectsChannelSet,
                patch: _withPayload({
                  'event': 'set',
                  'data': {'id': 'ch'}
                })),
            isNull);
      });

      test('objects of unknown type', () {
        expect(
            _event(_objectsChannelSet,
                patch: _withPayload({
                  'event': 'set',
                  'type': 'space',
                  'data': {'id': 'ch'}
                })),
            isNull);
      });

      test('message action without data', () {
        expect(
            _event(_messageActionAdded,
                patch: _withPayload({'event': 'added', 'source': 'actions'})),
            isNull);
      });

      test('file with a non map payload', () {
        expect(_event(_file, patch: _withPayload('just text')), isNull);
      });

      test('DataSync of unknown type', () {
        expect(
            _event(_dataSyncEntityCreate,
                patch: _withPayload({
                  'version': '1.0',
                  'metadata': {
                    'event': 'create',
                    'source': 'data-sync',
                    'type': 'project'
                  },
                  'data': {'id': 'x'}
                })),
            isNull);
      });

      test('DataSync without id', () {
        expect(
            _event(_dataSyncEntityCreate,
                patch: _withPayload({
                  'version': '1.0',
                  'metadata': {
                    'event': 'create',
                    'source': 'data-sync',
                    'type': 'entity'
                  },
                  'data': {'payload': {}}
                })),
            isNull);
      });
    });
  });

  group('Subscription streams', () {
    late PubNub pubnub;

    setUp(() {
      pubnub =
          PubNub(networking: FakeNetworkingModule(), defaultKeyset: _keyset);
    });

    test('route every event to its own stream and discard unknown events',
        () async {
      var batch = [
        _presenceJoin,
        _message,
        _signal,
        _messageActionAdded,
        _file,
        _objectsChannelSet,
        _objectsUuidSet,
        _objectsMembershipSet,
        _dataSyncEntityCreate,
        _unknownType,
        _presenceStateChange,
      ].map((wire) => json.decode(wire)).toList();

      when(
        method: 'GET',
        path: 'v2/subscribe/demo/ch,ch-pnpres/0?tt=0&uuid=test',
      ).then(
          status: 200, body: '{"t":{"t":"17905741222336765","r":41},"m":[]}');
      when(
        method: 'GET',
        path:
            'v2/subscribe/demo/ch,ch-pnpres/0?tt=17905741222336765&tr=41&uuid=test',
      ).then(
          status: 200,
          body: json.encode({
            't': {'t': '17905741900000001', 'r': 41},
            'm': batch
          }));

      var subscription =
          pubnub.subscription(channels: {'ch'}, withPresence: true);

      var events = <SubscriptionEvent>[];
      var messages = <Envelope>[];
      var presence = <PresenceEvent>[];
      var signals = <SignalEvent>[];
      var messageActions = <MessageActionEvent>[];
      var files = <FileEvent>[];
      var objects = <ObjectsEvent>[];
      var dataSync = <DataSyncEvent>[];

      // Ten recognized events are expected; the unknown one is discarded.
      var allReceived = Completer<void>();
      void ignore(Object _) {}
      subscription.events.listen((event) {
        events.add(event);
        if (events.length == 10) allReceived.complete();
      }, onError: ignore);
      subscription.messages.listen(messages.add, onError: ignore);
      subscription.presence.listen(presence.add, onError: ignore);
      subscription.signals.listen(signals.add, onError: ignore);
      subscription.messageActions.listen(messageActions.add, onError: ignore);
      subscription.files.listen(files.add, onError: ignore);
      subscription.objects.listen(objects.add, onError: ignore);
      subscription.dataSync.listen(dataSync.add, onError: ignore);

      subscription.subscribe();

      await allReceived.future.timeout(Duration(seconds: 5));
      await Future<void>.delayed(Duration(milliseconds: 50));

      expect(events.map((e) => e.runtimeType), [
        PresenceEvent,
        MessageEvent,
        SignalEvent,
        MessageActionEvent,
        FileEvent,
        ChannelMetadataEvent,
        UuidMetadataEvent,
        MembershipMetadataEvent,
        DataSyncEvent,
        PresenceEvent,
      ]);

      expect(messages, hasLength(1));
      expect(messages.single.payload, equals({'text': 'hello'}));
      expect(presence.map((e) => e.action),
          [PresenceAction.join, PresenceAction.stateChange]);
      expect(signals.single.message, equals('typing'));
      expect(messageActions.single.action.value, equals('smile'));
      expect(files.single.file!.name, equals('cat.png'));
      expect(objects.map((e) => e.runtimeType),
          [ChannelMetadataEvent, UuidMetadataEvent, MembershipMetadataEvent]);
      expect(dataSync.single.id, equals('dartcustomer.40601'));

      await subscription.cancel();
    });
  });
}
