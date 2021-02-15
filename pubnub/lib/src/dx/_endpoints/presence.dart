import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class HeartbeatParams extends Parameters {
  Keyset keyset;
  Set<String> channels;
  Set<String> channelGroups;

  int heartbeat;
  String state;

  HeartbeatParams(this.keyset,
      {this.channels, this.channelGroups, this.heartbeat, this.state});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'presence',
      'sub_key',
      keyset.subscribeKey,
      'channel',
      channels.isNotEmpty ? channels.join(',') : ',',
      'heartbeat'
    ];

    var queryParameters = {
      if (channelGroups != null && channelGroups.isNotEmpty)
        'channel-group': channelGroups.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid.value}',
      if (state != null) 'state': '$state',
      if (heartbeat != null) 'heartbeat': '$heartbeat'
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of heartbeat endpoint call.
///
/// {@category Results}
class HeartbeatResult extends Result {
  HeartbeatResult._();

  /// @nodoc
  factory HeartbeatResult.fromJson(dynamic _object) => HeartbeatResult._();
}

class SetUserStateParams extends Parameters {
  Keyset keyset;
  Set<String> channels;
  Set<String> channelGroups;

  String state;

  SetUserStateParams(this.keyset, this.state,
      {this.channels, this.channelGroups});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'presence',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      channels.isNotEmpty ? channels.join(',') : ',',
      'uuid',
      keyset.uuid.value,
      'data'
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      'state': '$state',
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of set user state endpoint call.
///
/// {@category Results}
class SetUserStateResult extends Result {
  String state;

  SetUserStateResult._();

  /// @nodoc
  factory SetUserStateResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return SetUserStateResult._()
      ..state = result.otherKeys['payload'] as String;
  }
}

class GetUserStateParams extends Parameters {
  Keyset keyset;
  Set<String> channels;
  Set<String> channelGroups;

  GetUserStateParams(this.keyset, {this.channels, this.channelGroups});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'presence',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      channels.isNotEmpty ? channels.join(',') : ',',
      'uuid',
      keyset.uuid.value
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of get user state endpoint call.
///
/// {@category Results}
class GetUserStateResult extends Result {
  String state;

  GetUserStateResult._();

  /// @nodoc
  factory GetUserStateResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return GetUserStateResult._()
      ..state = result.otherKeys['payload'] as String;
  }
}

class LeaveParams extends Parameters {
  Keyset keyset;
  Set<String> channels;
  Set<String> channelGroups;

  LeaveParams(this.keyset, {this.channels, this.channelGroups});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'presence',
      'sub_key',
      keyset.subscribeKey,
      'channel',
      channels.isNotEmpty ? channels.join(',') : ',',
      'leave'
    ];

    var queryParameters = {
      if (channelGroups != null && channelGroups.isNotEmpty)
        'channel-group': channelGroups.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid.value}',
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of leave endpoint call.
///
/// {@category Results}
class LeaveResult extends Result {
  String action;

  LeaveResult._();

  /// @nodoc
  factory LeaveResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return LeaveResult._()..action = result.otherKeys['action'] as String;
  }
}

/// Represents an amount of state requested.
enum StateInfo { all, onlyUUIDs, none }

class HereNowParams extends Parameters {
  Keyset keyset;

  bool global;
  Set<String> channels;
  Set<String> channelGroups;
  StateInfo stateInfo;

  HereNowParams(this.keyset,
      {this.global = false,
      this.channels,
      this.channelGroups,
      this.stateInfo = StateInfo.onlyUUIDs});

  @override
  Request toRequest() {
    var pathSegments = global == true
        ? ['v2', 'presence', 'sub_key', keyset.subscribeKey]
        : [
            'v2',
            'presence',
            'sub_key',
            keyset.subscribeKey,
            'channel',
            channels.isNotEmpty ? channels.join(',') : ','
          ];

    var queryParameters = {
      if (global != true && channelGroups != null && channelGroups.isNotEmpty)
        'channel-group': channelGroups.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid.value}',
      if (stateInfo == StateInfo.all || stateInfo == StateInfo.onlyUUIDs)
        'disable_uuids': '0',
      if (stateInfo == StateInfo.all) 'state': '1'
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Represents current channel participants.
///
/// {@category Results}
class ChannelOccupancy {
  String channelName;
  Map<String, UUID> uuids;
  int count;

  ChannelOccupancy(this.channelName, this.uuids, this.count);

  factory ChannelOccupancy.fromJson(
      String channelName, Map<String, dynamic> channelObject) {
    var uuids = <String, UUID>{};

    if (channelObject['uuids'] != null) {
      for (var uuid in channelObject['uuids']) {
        if (uuid is String) {
          uuids[uuid] = UUID(uuid);
        } else if (uuid is Map<String, dynamic>) {
          uuids[uuid['uuid'] as String] = UUID(uuid['uuid'] as String,
              state: uuid['state'] as Map<String, dynamic>);
        }
      }
    }

    return ChannelOccupancy(
        channelName, uuids, channelObject['occupancy'] as int);
  }
}

/// Result of here now endpoint call.
///
/// {@category Results}
class HereNowResult extends Result {
  Map<String, ChannelOccupancy> channels = {};

  int totalOccupancy;
  int totalChannels;

  HereNowResult._();

  factory HereNowResult.fromJson(Map<String, dynamic> object,
      {String channelName}) {
    var result = DefaultResult.fromJson(object);
    if (result.otherKeys.containsKey('payload')) {
      var payload = result.otherKeys['payload'] as Map<String, dynamic>;

      return HereNowResult._()
        ..totalChannels = payload['total_channels'] as int
        ..totalOccupancy = payload['total_occupancy'] as int
        ..channels = (payload['channels'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key,
                ChannelOccupancy.fromJson(key, value as Map<String, dynamic>)));
    } else {
      return HereNowResult._()
        ..channels = {
          channelName: ChannelOccupancy.fromJson(channelName, result.otherKeys)
        }
        ..totalOccupancy = result.otherKeys['occupancy'] as int
        ..totalChannels = 1;
    }
  }
}

class WhereNowParams extends Parameters {
  Keyset keyset;
  UUID uuid;

  WhereNowParams(this.keyset, this.uuid);

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'presence',
      'sub-key',
      keyset.subscribeKey,
      'uuid',
      uuid.value
    ];

    var queryParameters = {
      if (keyset.uuid != null) 'uuid': keyset.uuid,
      if (keyset.authKey != null) 'auth': keyset.authKey
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of where now endpoint call.
///
/// {@category Results}
class WhereNowResult extends Result {
  Set<String> channels;

  WhereNowResult._();

  factory WhereNowResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);
    var payload = result.otherKeys['payload'] as Map<String, dynamic>;
    return WhereNowResult._()..channels = Set.from(payload['channels'] ?? []);
  }
}
