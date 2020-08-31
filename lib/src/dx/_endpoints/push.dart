import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

enum PushGateway { apns, fcm, gcm, mpns, apns2 }

enum Environment { development, production }

extension EnvironmentExtension on Environment {
  String value() {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.production:
        return 'production';
      default:
        throw Exception('Invalid Gateway Type');
    }
  }
}

extension PushGatewayExtension on PushGateway {
  String value() {
    switch (this) {
      case PushGateway.fcm:
        return 'gcm';
      case PushGateway.gcm:
        return 'gcm';
      case PushGateway.apns:
        return 'apns';
      case PushGateway.mpns:
        return 'apns';
      case PushGateway.apns2:
        return 'apns2';
      default:
        throw Exception('Invalid Gateway Type');
    }
  }
}

class ListPushChannelsParams extends Parameters {
  Keyset keyset;
  String deviceId;

  PushGateway pushGateway;
  Environment environment;
  String topic;

  ListPushChannelsParams(this.keyset, this.deviceId, this.pushGateway,
      {this.topic, this.environment});

  @override
  Request toRequest() {
    var pathSegments = [
      pushGateway == PushGateway.apns2 ? 'v2' : 'v1',
      'push',
      'sub-key',
      keyset.subscribeKey,
      pushGateway == PushGateway.apns2 ? 'devices-apns2' : 'devices',
      deviceId,
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}',
      'type': pushGateway.value()
    };
    if (pushGateway == PushGateway.apns2) {
      queryParameters['environment'] =
          environment != null ? environment.value() : 'development';
      queryParameters['topic'] = topic;
      queryParameters.remove('type');
    }
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class ListPushChannelsResult extends Result {
  List<dynamic> channels;

  ListPushChannelsResult();

  factory ListPushChannelsResult.fromJson(dynamic object) {
    if (object is List) {
      return ListPushChannelsResult()..channels = object;
    }

    throw getExceptionFromDefaultResult(DefaultResult.fromJson(object));
  }
}

class AddPushChannelsParams extends Parameters {
  Keyset keyset;
  String deviceId;
  Set<String> channels;
  PushGateway pushGateway;
  Environment environment;
  String topic;

  AddPushChannelsParams(
      this.keyset, this.deviceId, this.pushGateway, this.channels,
      {this.topic, this.environment});

  @override
  Request toRequest() {
    var pathSegments = [
      pushGateway == PushGateway.apns2 ? 'v2' : 'v1',
      'push',
      'sub-key',
      keyset.subscribeKey,
      pushGateway == PushGateway.apns2 ? 'devices-apns2' : 'devices',
      deviceId,
    ];
    var queryParameters = {
      if (channels.isNotEmpty) 'add': channels.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}',
      'type': pushGateway.value()
    };
    if (pushGateway == PushGateway.apns2) {
      queryParameters['environment'] =
          environment != null ? environment.value() : 'development';
      queryParameters['topic'] = topic;
      queryParameters.remove('type');
    }
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class AddPushChannelsResult extends Result {
  int status;
  String description;
  AddPushChannelsResult();
  factory AddPushChannelsResult.fromJson(dynamic object) {
    if (object is List) {
      return AddPushChannelsResult()
        ..status = object[0]
        ..description = object[1];
    }

    throw getExceptionFromDefaultResult(DefaultResult.fromJson(object));
  }
}

class RemovePushChannelsParams extends Parameters {
  Keyset keyset;
  String deviceId;
  Set<String> channels;
  PushGateway pushGateway;
  Environment environment;
  String topic;

  RemovePushChannelsParams(
      this.keyset, this.deviceId, this.pushGateway, this.channels,
      {this.topic, this.environment});

  @override
  Request toRequest() {
    var pathSegments = [
      pushGateway == PushGateway.apns2 ? 'v2' : 'v1',
      'push',
      'sub-key',
      keyset.subscribeKey,
      pushGateway == PushGateway.apns2 ? 'devices-apns2' : 'devices',
      deviceId,
    ];
    var queryParameters = {
      if (channels.isNotEmpty) 'remove': channels.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}',
      'type': pushGateway.value()
    };
    if (pushGateway == PushGateway.apns2) {
      queryParameters['environment'] =
          environment != null ? environment.value() : 'development';
      queryParameters['topic'] = topic;
      queryParameters.remove('type');
    }
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class RemovePushChannelsResult extends Result {
  int status;
  String description;
  RemovePushChannelsResult();
  factory RemovePushChannelsResult.fromJson(dynamic object) {
    if (object is List) {
      return RemovePushChannelsResult()
        ..status = object[0]
        ..description = object[1];
    }

    throw getExceptionFromDefaultResult(DefaultResult.fromJson(object));
  }
}

class RemoveDeviceParams extends Parameters {
  Keyset keyset;
  String deviceId;

  PushGateway pushGateway;
  Environment environment;
  String topic;

  RemoveDeviceParams(this.keyset, this.deviceId, this.pushGateway,
      {this.topic, this.environment});

  @override
  Request toRequest() {
    var pathSegments = [
      pushGateway == PushGateway.apns2 ? 'v2' : 'v1',
      'push',
      'sub-key',
      keyset.subscribeKey,
      pushGateway == PushGateway.apns2 ? 'devices-apns2' : 'devices',
      deviceId,
      'remove'
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}',
      'type': pushGateway.value()
    };
    if (pushGateway == PushGateway.apns2) {
      queryParameters['environment'] =
          environment != null ? environment.value() : 'development';
      queryParameters['topic'] = topic;
      queryParameters.remove('type');
    }
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class RemoveDeviceResult extends Result {
  int status;
  String description;
  RemoveDeviceResult();
  factory RemoveDeviceResult.fromJson(dynamic object) {
    if (object is List) {
      return RemoveDeviceResult()
        ..status = object[0]
        ..description = object[1];
    }

    throw getExceptionFromDefaultResult(DefaultResult.fromJson(object));
  }
}
