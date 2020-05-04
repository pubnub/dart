@Timeout(Duration(seconds: 55))
import 'package:test/test.dart';

import 'objects/objects.dart';

import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/_endpoints/push.dart';
import 'package:pubnub/src/dx/push/push.dart';

import '../net/fake_net.dart';
part './fixtures/push.dart';

void main() {
  PubNub pubnub;
  group('DX [pushNotification]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(Keyset(subscribeKey: 'test', publishKey: 'test'),
            name: 'default', useAsDefault: true);
    });
    test('listPushChannels throws for empty deviceId', () {
      expect(pubnub.listPushChannels('', PushGateway.gcm),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('listPushChannels throws if no keyset found', () async {
      pubnub.keysets.remove('default');
      var deviceId = 'A332C23D';
      expect(pubnub.listPushChannels(deviceId, PushGateway.gcm),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('listPushChannels returns valid response for non apns2 gateway',
        () async {
      var deviceId = 'A332C23D';
      when(
        path:
            'v1/push/sub-key/test/devices/A332C23D?type=gcm&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '["ch1", "ch2"]');
      var response = await pubnub.listPushChannels(deviceId, PushGateway.gcm);
      expect(response, isA<ListPushChannelsResult>());
    });

    test(
        'listPushChannels throws when topic is not provided with apns2 gateway',
        () async {
      var deviceId = 'A332C23D';
      expect(pubnub.listPushChannels(deviceId, PushGateway.apns2),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test(
        'listPushChannels should return valid response for apns2 with default development env',
        () async {
      var deviceId = 'A332C23D';
      var topic = 'topic';
      when(
        path:
            'v2/push/sub-key/test/devices-apns2/A332C23D?environment=development&topic=topic&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '["ch1", "ch2"]');
      var response = await pubnub.listPushChannels(deviceId, PushGateway.apns2,
          topic: topic);
      expect(response, isA<ListPushChannelsResult>());
    });

    test(
        'listPushChannels should return valid response for apns2 with mentioned development env',
        () async {
      var deviceId = 'A332C23D';
      var topic = 'topic';
      when(
        path:
            'v2/push/sub-key/test/devices-apns2/A332C23D?environment=production&topic=topic&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '["ch1", "ch2"]');
      var response = await pubnub.listPushChannels(deviceId, PushGateway.apns2,
          topic: topic, environment: Environment.production);
      expect(response, isA<ListPushChannelsResult>());
      expect(response.channels[0] as String, isNotNull);
    });

    test('addPushChannels throws if no keyset found', () async {
      pubnub.keysets.remove('default');
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.addPushChannels(deviceId, PushGateway.gcm, channels),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('addPushChannels throws for empty deviceId', () {
      var deviceId = '';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.addPushChannels(deviceId, PushGateway.gcm, channels),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('addPushChannels returns valid response', () async {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      when(
        path:
            'v1/push/sub-key/test/devices/A332C23D?add=ch1%2Cch2&type=gcm&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[1, "ch1", "ch2"]');
      var response =
          await pubnub.addPushChannels(deviceId, PushGateway.gcm, channels);
      expect(response, isA<AddPushChannelsResult>());
    });

    test('addPushChannels throws when topic null with apns2', () {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.addPushChannels(deviceId, PushGateway.apns2, channels),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('addPushChannels returns valid response with apns2', () async {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      var topic = 'topic';
      when(
        path:
            'v2/push/sub-key/test/devices-apns2/A332C23D?add=ch1%2Cch2&environment=production&topic=topic&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[1,"ch1,ch2"]');
      var response = await pubnub.addPushChannels(
          deviceId, PushGateway.apns2, channels,
          topic: topic, environment: Environment.production);
      expect(response, isA<AddPushChannelsResult>());
    });

    test('removePushChannels throws if no keyset found', () async {
      pubnub.keysets.remove('default');
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.removePushChannels(deviceId, PushGateway.gcm, channels),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('removePushChannels throws for empty deviceId', () {
      var deviceId = '';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.removePushChannels(deviceId, PushGateway.gcm, channels),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('removePushChannels returns valid response', () async {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      when(
        path:
            'v1/push/sub-key/test/devices/A332C23D?remove=ch1%2Cch2&type=gcm&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[1, "ch1", "ch2"]');
      var response =
          await pubnub.removePushChannels(deviceId, PushGateway.gcm, channels);
      expect(response, isA<RemovePushChannelsResult>());
    });

    test('removePushChannels throws when topic null with apns2', () {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.removePushChannels(deviceId, PushGateway.apns2, channels),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('removePushChannels returns valid response with apns2', () async {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      var topic = 'topic';
      when(
        path:
            'v2/push/sub-key/test/devices-apns2/A332C23D?remove=ch1%2Cch2&environment=production&topic=topic&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[1, "ch1", "ch2"]');
      var response = await pubnub.removePushChannels(
          deviceId, PushGateway.apns2, channels,
          topic: topic, environment: Environment.production);
      expect(response, isA<RemovePushChannelsResult>());
    });

    test('removeDevice throws if no keyset found', () async {
      pubnub.keysets.remove('default');
      var deviceId = 'A332C23D';
      expect(pubnub.removeDevice(deviceId, PushGateway.gcm),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('removeDevice throws for empty deviceId', () {
      var deviceId = '';
      expect(pubnub.removeDevice(deviceId, PushGateway.gcm),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('removeDevice returns valid response', () async {
      var deviceId = 'A332C23D';
      when(
        path:
            'v1/push/sub-key/test/devices/A332C23D/remove?type=gcm&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[1, "Device Removed"]');
      var response = await pubnub.removeDevice(deviceId, PushGateway.gcm);
      expect(response, isA<RemoveDeviceResult>());
    });

    test('removeDevice throws when topic is null with apns2', () {
      var deviceId = 'A332C23D';
      expect(pubnub.removeDevice(deviceId, PushGateway.apns2),
          throwsA(TypeMatcher<InvariantException>()));
    });
    test('removeDevice returns valid response with apns2', () async {
      var deviceId = 'A332C23D';
      var topic = 'topic';
      when(
        path:
            'v2/push/sub-key/test/devices-apns2/A332C23D/remove?environment=production&topic=topic&pnsdk=PubNub-Dart%2F${PubNub.version}',
        method: 'GET',
      ).then(status: 200, body: '[1, "Device Removed"]');
      var response = await pubnub.removeDevice(deviceId, PushGateway.apns2,
          topic: topic, environment: Environment.production);
      expect(response, isA<RemoveDeviceResult>());
    });
    test('device should return an instance of Device', () {
      var deviceId = 'A332C23D';
      var device = pubnub.device(deviceId);

      expect(device, isA<Device>());
    });

    group('[device]', () {
      Device device;
      FakePubNub fakePubnub;
      Keyset keyset;
      var deviceId = 'A332C23D';
      setUp(() {
        fakePubnub = FakePubNub();
        keyset = Keyset(subscribeKey: 'test', publishKey: 'test');
        device = Device(fakePubnub, keyset, deviceId);
      });
      test('device should delegate to pushChannels.addPushChannels', () {
        device.registerToChannels(<String>{'ch1', 'ch2'}, PushGateway.mpns);

        var invocation = fakePubnub.invocations[0];

        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#addPushChannels));
        expect(
            invocation.positionalArguments,
            equals([
              'A332C23D',
              PushGateway.mpns,
              <String>{'ch1', 'ch2'}
            ]));
        expect(
            invocation.namedArguments,
            equals({
              #keyset: keyset,
              #using: null,
              #topic: null,
              #environment: null
            }));
      });

      test('device should delegate to pushChannels.removePushChannels', () {
        device.deregisterFromChannels(<String>{'ch1', 'ch2'}, PushGateway.mpns);

        var invocation = fakePubnub.invocations[0];

        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#removePushChannels));
        expect(
            invocation.positionalArguments,
            equals([
              'A332C23D',
              PushGateway.mpns,
              <String>{'ch1', 'ch2'}
            ]));
        expect(
            invocation.namedArguments,
            equals({
              #keyset: keyset,
              #using: null,
              #topic: null,
              #environment: null
            }));
      });

      test('device should delegate to pushChannels.removeDevice', () {
        device.remove(PushGateway.mpns);

        var invocation = fakePubnub.invocations[0];

        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#removeDevice));
        expect(invocation.positionalArguments,
            equals(['A332C23D', PushGateway.mpns]));
        expect(
            invocation.namedArguments,
            equals({
              #keyset: keyset,
              #using: null,
              #topic: null,
              #environment: null
            }));
      });
    });
  });
}
