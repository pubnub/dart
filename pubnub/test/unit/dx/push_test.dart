import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';
import 'package:pubnub/src/dx/_endpoints/push.dart';

import '../net/fake_net.dart';
part './fixtures/push.dart';

void main() {
  late PubNub pubnub;

  // URL Generation Tests for PushGateway enum usage
  group('DX [pushNotification] URL Generation Tests', () {
    late Keyset keyset;

    setUp(() {
      keyset = Keyset(
        subscribeKey: 'test-sub-key',
        publishKey: 'test-pub-key',
        uuid: UUID('test-uuid'),
        authKey: 'test-auth-key',
      );
    });

    group('ListPushChannelsParams URL generation', () {
      test('generates correct URL for FCM gateway', () {
        var params = ListPushChannelsParams(
          keyset,
          'device123',
          PushGateway.fcm,
          start: 'ch1',
          count: 100,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v1',
              'push',
              'sub-key',
              'test-sub-key',
              'devices',
              'device123'
            ]));
        expect(request.uri!.queryParameters['type'], equals('fcm'));
        expect(request.uri!.queryParameters['uuid'], equals('test-uuid'));
        expect(request.uri!.queryParameters['auth'], equals('test-auth-key'));
        expect(request.uri!.queryParameters['start'], equals('ch1'));
        expect(request.uri!.queryParameters['count'], equals('100'));
      });

      test('generates correct URL for GCM gateway (maps to FCM)', () {
        var params = ListPushChannelsParams(
          keyset,
          'device123',
          PushGateway.gcm,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v1',
              'push',
              'sub-key',
              'test-sub-key',
              'devices',
              'device123'
            ]));
        expect(request.uri!.queryParameters['type'], equals('fcm'));
      });

      test('generates correct URL for APNS gateway', () {
        var params = ListPushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v1',
              'push',
              'sub-key',
              'test-sub-key',
              'devices',
              'device123'
            ]));
        expect(request.uri!.queryParameters['type'], equals('apns'));
      });

      test('generates correct URL for MPNS gateway', () {
        var params = ListPushChannelsParams(
          keyset,
          'device123',
          PushGateway.mpns,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v1',
              'push',
              'sub-key',
              'test-sub-key',
              'devices',
              'device123'
            ]));
        expect(request.uri!.queryParameters['type'], equals('mpns'));
      });

      test(
          'generates correct URL for APNS2 gateway with development environment',
          () {
        var params = ListPushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns2,
          topic: 'com.example.app',
          environment: Environment.development,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v2',
              'push',
              'sub-key',
              'test-sub-key',
              'devices-apns2',
              'device123'
            ]));
        expect(
            request.uri!.queryParameters['environment'], equals('development'));
        expect(
            request.uri!.queryParameters['topic'], equals('com.example.app'));
        expect(request.uri!.queryParameters.containsKey('type'), isFalse);
      });

      test(
          'generates correct URL for APNS2 gateway with production environment',
          () {
        var params = ListPushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns2,
          topic: 'com.example.app',
          environment: Environment.production,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v2',
              'push',
              'sub-key',
              'test-sub-key',
              'devices-apns2',
              'device123'
            ]));
        expect(
            request.uri!.queryParameters['environment'], equals('production'));
        expect(
            request.uri!.queryParameters['topic'], equals('com.example.app'));
        expect(request.uri!.queryParameters.containsKey('type'), isFalse);
      });

      test(
          'generates correct URL for APNS2 gateway with default development environment',
          () {
        var params = ListPushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns2,
          topic: 'com.example.app',
        );

        var request = params.toRequest();

        expect(
            request.uri!.queryParameters['environment'], equals('development'));
      });
    });

    group('AddPushChannelsParams URL generation', () {
      test('generates correct URL for FCM gateway', () {
        var params = AddPushChannelsParams(
          keyset,
          'device123',
          PushGateway.fcm,
          {'channel1', 'channel2'},
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v1',
              'push',
              'sub-key',
              'test-sub-key',
              'devices',
              'device123'
            ]));
        expect(request.uri!.queryParameters['type'], equals('fcm'));
        expect(
            request.uri!.queryParameters['add'], equals('channel1,channel2'));
      });

      test('generates correct URL for GCM gateway (maps to FCM)', () {
        var params = AddPushChannelsParams(
          keyset,
          'device123',
          PushGateway.gcm,
          {'channel1'},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('fcm'));
      });

      test('generates correct URL for APNS gateway', () {
        var params = AddPushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns,
          {'channel1'},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('apns'));
      });

      test('generates correct URL for MPNS gateway', () {
        var params = AddPushChannelsParams(
          keyset,
          'device123',
          PushGateway.mpns,
          {'channel1'},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('mpns'));
      });

      test('generates correct URL for APNS2 gateway', () {
        var params = AddPushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns2,
          {'channel1', 'channel2'},
          topic: 'com.example.app',
          environment: Environment.production,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v2',
              'push',
              'sub-key',
              'test-sub-key',
              'devices-apns2',
              'device123'
            ]));
        expect(
            request.uri!.queryParameters['environment'], equals('production'));
        expect(
            request.uri!.queryParameters['topic'], equals('com.example.app'));
        expect(
            request.uri!.queryParameters['add'], equals('channel1,channel2'));
        expect(request.uri!.queryParameters.containsKey('type'), isFalse);
      });
    });

    group('RemovePushChannelsParams URL generation', () {
      test('generates correct URL for FCM gateway', () {
        var params = RemovePushChannelsParams(
          keyset,
          'device123',
          PushGateway.fcm,
          {'channel1', 'channel2'},
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v1',
              'push',
              'sub-key',
              'test-sub-key',
              'devices',
              'device123'
            ]));
        expect(request.uri!.queryParameters['type'], equals('fcm'));
        expect(request.uri!.queryParameters['remove'],
            equals('channel1,channel2'));
      });

      test('generates correct URL for GCM gateway (maps to FCM)', () {
        var params = RemovePushChannelsParams(
          keyset,
          'device123',
          PushGateway.gcm,
          {'channel1'},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('fcm'));
      });

      test('generates correct URL for APNS gateway', () {
        var params = RemovePushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns,
          {'channel1'},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('apns'));
      });

      test('generates correct URL for MPNS gateway', () {
        var params = RemovePushChannelsParams(
          keyset,
          'device123',
          PushGateway.mpns,
          {'channel1'},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('mpns'));
      });

      test('generates correct URL for APNS2 gateway', () {
        var params = RemovePushChannelsParams(
          keyset,
          'device123',
          PushGateway.apns2,
          {'channel1', 'channel2'},
          topic: 'com.example.app',
          environment: Environment.development,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v2',
              'push',
              'sub-key',
              'test-sub-key',
              'devices-apns2',
              'device123'
            ]));
        expect(
            request.uri!.queryParameters['environment'], equals('development'));
        expect(
            request.uri!.queryParameters['topic'], equals('com.example.app'));
        expect(request.uri!.queryParameters['remove'],
            equals('channel1,channel2'));
        expect(request.uri!.queryParameters.containsKey('type'), isFalse);
      });
    });

    group('RemoveDeviceParams URL generation', () {
      test('generates correct URL for FCM gateway', () {
        var params = RemoveDeviceParams(
          keyset,
          'device123',
          PushGateway.fcm,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v1',
              'push',
              'sub-key',
              'test-sub-key',
              'devices',
              'device123',
              'remove'
            ]));
        expect(request.uri!.queryParameters['type'], equals('fcm'));
      });

      test('generates correct URL for GCM gateway (maps to FCM)', () {
        var params = RemoveDeviceParams(
          keyset,
          'device123',
          PushGateway.gcm,
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('fcm'));
      });

      test('generates correct URL for APNS gateway', () {
        var params = RemoveDeviceParams(
          keyset,
          'device123',
          PushGateway.apns,
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('apns'));
      });

      test('generates correct URL for MPNS gateway', () {
        var params = RemoveDeviceParams(
          keyset,
          'device123',
          PushGateway.mpns,
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters['type'], equals('mpns'));
      });

      test('generates correct URL for APNS2 gateway', () {
        var params = RemoveDeviceParams(
          keyset,
          'device123',
          PushGateway.apns2,
          topic: 'com.example.app',
          environment: Environment.production,
        );

        var request = params.toRequest();

        expect(
            request.uri!.pathSegments,
            equals([
              'v2',
              'push',
              'sub-key',
              'test-sub-key',
              'devices-apns2',
              'device123',
              'remove'
            ]));
        expect(
            request.uri!.queryParameters['environment'], equals('production'));
        expect(
            request.uri!.queryParameters['topic'], equals('com.example.app'));
        expect(request.uri!.queryParameters.containsKey('type'), isFalse);
      });
    });

    group('PushGatewayExtension value() method tests', () {
      test('FCM gateway returns correct value', () {
        expect(PushGateway.fcm.value(), equals('fcm'));
      });

      test('GCM gateway maps to FCM value', () {
        expect(PushGateway.gcm.value(), equals('fcm'));
      });

      test('APNS gateway returns correct value', () {
        expect(PushGateway.apns.value(), equals('apns'));
      });

      test('APNS2 gateway returns correct value', () {
        expect(PushGateway.apns2.value(), equals('apns2'));
      });

      test('MPNS gateway returns correct value', () {
        expect(PushGateway.mpns.value(), equals('mpns'));
      });
    });

    group('Edge cases and validation', () {
      test('handles empty channels set in AddPushChannelsParams', () {
        var params = AddPushChannelsParams(
          keyset,
          'device123',
          PushGateway.fcm,
          <String>{},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters.containsKey('add'), isFalse);
      });

      test('handles empty channels set in RemovePushChannelsParams', () {
        var params = RemovePushChannelsParams(
          keyset,
          'device123',
          PushGateway.fcm,
          <String>{},
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters.containsKey('remove'), isFalse);
      });

      test('handles keyset without authKey', () {
        var keysetNoAuth = Keyset(
          subscribeKey: 'test-sub-key',
          publishKey: 'test-pub-key',
          uuid: UUID('test-uuid'),
        );

        var params = ListPushChannelsParams(
          keysetNoAuth,
          'device123',
          PushGateway.fcm,
        );

        var request = params.toRequest();

        expect(request.uri!.queryParameters.containsKey('auth'), isFalse);
        expect(request.uri!.queryParameters['uuid'], equals('test-uuid'));
      });
    });
  });

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

      test('listPushChannels delegate supported arguments', () async {
        fakePubnub.returnWhen(
          #listPushChannels,
          Future.value(ListPushChannelsResult.fromJson(['ch1', 'ch2', 'ch3'])),
        );

        await fakePubnub.listPushChannels(
          'A332C23D',
          PushGateway.mpns,
          start: 'ch2',
          count: 10,
        );

        var invocation = fakePubnub.invocations[0];

        expect(invocation.isMethod, equals(true));
        expect(invocation.memberName, equals(#listPushChannels));
        expect(invocation.positionalArguments,
            equals(['A332C23D', PushGateway.mpns]));
        expect(
            invocation.namedArguments,
            equals({
              #keyset: null,
              #using: null,
              #topic: null,
              #environment: null,
              #start: 'ch2',
              #count: 10,
            }));
      });
    });
  });
}
