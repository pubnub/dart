import 'package:pubnub/core.dart';
import 'package:pubnub/src/default.dart';

import '../_utils/utils.dart';
import '../_endpoints/push.dart';

export '../_endpoints/push.dart';

// Managing device registrations for Push Notification Service
mixin PushNotificationDx on Core {
  /// It returns list of all channels to which device [deviceId] is registered to receive push notifications.
  ///
  /// [deviceId] is the id/token of the device.
  /// [gateway] indicates the backend to use for push service:
  /// * apns or apns2 for Apple service.
  /// * gcm for Google service.
  /// * mpns for Microsoft service.
  ///
  /// If [gateway] is [PushGateway.apns2] then [topic] is mandatory to provide.
  /// [topic] is bundle id of the mobile application.
  /// [environment] denoting the environment of the mobile application for [PushGateway.apns2], it can be either:
  /// * [Environment.development] (which is the default value).
  /// * [Environment.production].
  Future<ListPushChannelsResult> listPushChannels(
      String deviceId, PushGateway gateway,
      {String? topic,
      Environment? environment,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    Ensure(deviceId).isNotEmpty('deviceId');
    if (gateway == PushGateway.apns2) Ensure(topic).isNotNull('topic');

    var params = ListPushChannelsParams(keyset, deviceId, gateway,
        topic: topic, environment: environment);
    return defaultFlow<ListPushChannelsParams, ListPushChannelsResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => ListPushChannelsResult.fromJson(object));
  }

  /// It registers device [deviceId] for push notifications from [channels]
  /// So the device [deviceId] will receive push notifications from those channels mentioned in list [channels]
  ///
  /// [deviceId] is the id/token of the device
  /// [gateway] indicates the backend to use for push service
  /// it can be
  /// * apns or apns2 for apple service
  /// * gcm for google service
  /// * mpns for microsoft service
  ///
  /// If [gateway] is [PushGateway.apns2] then [topic] is mandatory to provide
  /// [topic] is bundle id of the mobile application
  /// [environment] denoting the environment of the mobile application for [PushGateway.apns2]
  /// it can be either [Environment.development] or [Environment.production]
  /// default value for [environment] is [Environment.development]
  Future<AddPushChannelsResult> addPushChannels(
      String deviceId, PushGateway gateway, Set<String> channels,
      {String? topic,
      Environment? environment,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    Ensure(deviceId).isNotEmpty('deviceId');
    if (gateway == PushGateway.apns2) Ensure(topic).isNotNull('topic');

    var params = AddPushChannelsParams(keyset, deviceId, gateway, channels,
        topic: topic, environment: environment);
    return defaultFlow<AddPushChannelsParams, AddPushChannelsResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => AddPushChannelsResult.fromJson(object));
  }

  /// It removes registration of device [deviceId] from [channels]
  /// So device [deviceId] will not get push notifications from [channels]
  ///
  /// [deviceId] is the id/token of the device
  /// [gateway] indicates the backend to use for push service
  /// it can be
  /// * apns or apns2 for apple service
  /// * gcm for google service
  /// * mpns for microsoft service
  ///
  /// If [gateway] is [PushGateway.apns2] then [topic] is mandatory to provide
  /// [topic] is bundle id of the mobile application
  /// [environment] denoting the environment of the mobile application for [PushGateway.apns2]
  /// it can be either [Environment.development] or [Environment.production]
  /// default value for [environment] is [Environment.development]
  Future<RemovePushChannelsResult> removePushChannels(
      String deviceId, PushGateway gateway, Set<String> channels,
      {String? topic,
      Environment? environment,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    Ensure(deviceId).isNotEmpty('deviceId');
    if (gateway == PushGateway.apns2) Ensure(topic).isNotNull('topic');

    var params = RemovePushChannelsParams(keyset, deviceId, gateway, channels,
        topic: topic, environment: environment);
    return defaultFlow<RemovePushChannelsParams, RemovePushChannelsResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => RemovePushChannelsResult.fromJson(object));
  }

  /// It is allowing for removal of all registered channels at once,
  /// for a given device [deviceId], without specifying all of the channels.
  ///
  /// [deviceId] is the id/token of the device
  /// [gateway] indicates the backend to use for push service
  /// it can be
  /// * apns or apns2 for apple service
  /// * gcm for google service
  /// * mpns for microsoft service
  ///
  /// If [gateway] is [PushGateway.apns2] then [topic] is mandatory to provide
  /// [topic] is bundle id of the mobile application
  /// [environment] denoting the environment of the mobile application for [PushGateway.apns2]
  /// it can be either [Environment.development] or [Environment.production]
  /// default value for [environment] is [Environment.development]
  Future<RemoveDeviceResult> removeDevice(String deviceId, PushGateway gateway,
      {String? topic,
      Environment? environment,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    Ensure(deviceId).isNotEmpty('deviceId');
    if (gateway == PushGateway.apns2) Ensure(topic).isNotNull('topic');

    var params = RemoveDeviceParams(keyset, deviceId, gateway,
        topic: topic, environment: environment);
    return defaultFlow<RemoveDeviceParams, RemoveDeviceResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => RemoveDeviceResult.fromJson(object));
  }
}

/// Represents a device used in push endpoints.
class Device {
  final PubNub _core;
  final Keyset _keyset;
  String deviceId;

  Device(this._core, this._keyset, this.deviceId);

  /// Use this method register the device [deviceId] to recieve push notifications from [channels]
  /// Provide apropriate value of push service backend [gateway]
  ///
  /// In case of apns2 gateway please provide topic and environment(default: development) values
  Future<AddPushChannelsResult> registerToChannels(
      Set<String> channels, PushGateway gateway,
      {String? topic, Environment? environment}) {
    return _core.addPushChannels(deviceId, gateway, channels,
        topic: topic, environment: environment, keyset: _keyset);
  }

  /// Use this method to deregister the device [deviceId] from recieve push notifications for [channels]
  /// Provide apropriate value of push service backend [gateway]
  ///
  /// In case of apns2 gateway please provide topic and environment(default: development) values
  Future<RemovePushChannelsResult> deregisterFromChannels(
      Set<String> channels, PushGateway gateway,
      {String? topic, Environment? environment}) {
    return _core.removePushChannels(deviceId, gateway, channels,
        topic: topic, environment: environment, keyset: _keyset);
  }

  /// Use this method to deregister the device [deviceId] from all push notification channels
  /// This method is allowing for removal of all registered channels at once, for a given device, without specifying all of the channels
  /// Provide apropriate value of push service backend [gateway]
  ///
  /// In case of apns2 gateway please provide topic and environment(default: development) values
  Future<RemoveDeviceResult> remove(PushGateway gateway,
      {String? topic, Environment? environment}) {
    return _core.removeDevice(deviceId, gateway,
        topic: topic, environment: environment, keyset: _keyset);
  }
}
