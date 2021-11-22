import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_endpoints/push.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import '../net/fake_net.dart';
part './fixtures/push.dart';

void main() {
  late PubNub pubnub;
  group('DX [pushNotification]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test', publishKey: 'test', uuid: UUID('test')),
          networking: FakeNetworkingModule());
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

    test(
        'listPushChannels throws when topic is not provided with apns2 gateway',
        () async {
      var deviceId = 'A332C23D';
      expect(pubnub.listPushChannels(deviceId, PushGateway.apns2),
          throwsA(TypeMatcher<InvariantException>()));
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

    test('addPushChannels throws when topic null with apns2', () {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.addPushChannels(deviceId, PushGateway.apns2, channels),
          throwsA(TypeMatcher<InvariantException>()));
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

    test('removePushChannels throws when topic null with apns2', () {
      var deviceId = 'A332C23D';
      var channels = <String>{'ch1', 'ch2'};
      expect(pubnub.removePushChannels(deviceId, PushGateway.apns2, channels),
          throwsA(TypeMatcher<InvariantException>()));
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

    test('removeDevice throws when topic is null with apns2', () {
      var deviceId = 'A332C23D';
      expect(pubnub.removeDevice(deviceId, PushGateway.apns2),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('device should return an instance of Device', () {
      var deviceId = 'A332C23D';
      var device = pubnub.device(deviceId);

      expect(device, isA<Device>());
    });

    group('[device]', () {
      late Device device;
      late FakePubNub fakePubnub;
      late Keyset keyset;
      var deviceId = 'A332C23D';
      setUp(() {
        fakePubnub = FakePubNub();
        keyset = Keyset(
            subscribeKey: 'test', publishKey: 'test', uuid: UUID('test'));
        device = Device(fakePubnub, keyset, deviceId);
      });
      test('device should delegate to pushChannels.addPushChannels', () {
        fakePubnub.returnWhen(#addPushChannels,
            Future.value(AddPushChannelsResult.fromJson([0, ''])));

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
        fakePubnub.returnWhen(#removePushChannels,
            Future.value(RemovePushChannelsResult.fromJson([0, ''])));

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
        fakePubnub.returnWhen(
            #removeDevice, Future.value(RemoveDeviceResult.fromJson([0, ''])));
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
