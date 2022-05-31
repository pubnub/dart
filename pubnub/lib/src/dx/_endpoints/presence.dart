import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class HeartbeatParams extends Parameters {
  Keyset keyset;
  Set<String>? channels;
  Set<String>? channelGroups;

  int? heartbeat;
  String? state;

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
      if (channels != null) channels!.isNotEmpty ? channels!.join(',') : ',',
      'heartbeat'
    ];

    var queryParameters = {
      if (channelGroups != null && channelGroups!.isNotEmpty)
        'channel-group': channelGroups?.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      'uuid': '${keyset.uuid.value}',
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
  Set<String>? channels;
  Set<String>? channelGroups;

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
      if (channels != null) channels!.isNotEmpty ? channels!.join(',') : ',',
      'uuid',
      keyset.uuid.value,
      'data'
    ];

    var queryParameters = {
      if (channelGroups != null && channelGroups!.isNotEmpty)
        'channel-group': channelGroups!.join(','),
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
  final dynamic state;

  SetUserStateResult._(this.state);

  /// @nodoc
  factory SetUserStateResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return SetUserStateResult._(result.otherKeys['payload']);
  }
}

class GetUserStateParams extends Parameters {
  Keyset keyset;
  Set<String>? channels;
  Set<String>? channelGroups;

  GetUserStateParams(this.keyset, {this.channels, this.channelGroups});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'presence',
      'sub-key',
      keyset.subscribeKey,
      'channel',
      if (channels != null) channels!.isNotEmpty ? channels!.join(',') : ',',
      'uuid',
      keyset.uuid.value
    ];

    var queryParameters = {
      if (channelGroups != null && channelGroups!.isNotEmpty)
        'channel-group': channelGroups!.join(','),
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
  final dynamic state;

  GetUserStateResult._(this.state);

  /// @nodoc
  factory GetUserStateResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return GetUserStateResult._(result.otherKeys['payload']);
  }
}

class LeaveParams extends Parameters {
  Keyset keyset;
  Set<String>? channels;
  Set<String>? channelGroups;

  LeaveParams(this.keyset, {this.channels, this.channelGroups});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'presence',
      'sub_key',
      keyset.subscribeKey,
      'channel',
      if (channels != null) channels!.isNotEmpty ? channels!.join(',') : ',',
      'leave'
    ];

    var queryParameters = {
      if (channelGroups != null && channelGroups!.isNotEmpty)
        'channel-group': channelGroups!.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      'uuid': '${keyset.uuid.value}',
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of leave endpoint call.
///
/// {@category Results}
class LeaveResult extends Result {
  final String action;

  LeaveResult._(this.action);

  /// @nodoc
  factory LeaveResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);

    return LeaveResult._(result.otherKeys['action'] as String);
  }
}

/// Represents an amount of state requested.
enum StateInfo { all, onlyUUIDs, none }

class HereNowParams extends Parameters {
  Keyset keyset;

  bool global;
  Set<String>? channels;
  Set<String>? channelGroups;
  StateInfo? stateInfo;

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
            if (channels != null)
              channels!.isNotEmpty ? channels!.join(',') : ','
          ];

    var queryParameters = {
      if (global != true && channelGroups != null && channelGroups!.isNotEmpty)
        'channel-group': channelGroups!.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      'uuid': '${keyset.uuid.value}',
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
  Map<String, OccupantInfo> uuids;
  int count;

  ChannelOccupancy(this.channelName, this.uuids, this.count);

  factory ChannelOccupancy.fromJson(
      String channelName, Map<String, dynamic> channelObject) {
    var uuids = <String, OccupantInfo>{};

    if (channelObject['uuids'] != null) {
      for (var uuid in channelObject['uuids']) {
        if (uuid is String) {
          uuids[uuid] = OccupantInfo(uuid);
        } else if (uuid is Map<String, dynamic>) {
          uuids[uuid['uuid'] as String] = OccupantInfo(uuid['uuid'] as String,
              state: uuid['state'] as Map<String, dynamic>);
        }
      }
    }

    return ChannelOccupancy(
        channelName, uuids, channelObject['occupancy'] as int);
  }
}

class OccupantInfo {
  String uuid;
  Map<String, dynamic>? state;

  OccupantInfo(this.uuid, {this.state});

  factory OccupantInfo.fromJson(dynamic json) =>
      OccupantInfo(json['uuid'], state: json['state']);
}

/// Result of here now endpoint call.
///
/// {@category Results}
class HereNowResult extends Result {
  Map<String?, ChannelOccupancy> channels = {};

  final int totalOccupancy;
  final int totalChannels;

  HereNowResult._(this.channels, this.totalOccupancy, this.totalChannels);

  factory HereNowResult.fromJson(Map<String, dynamic> object,
      {String? channelName}) {
    var result = DefaultResult.fromJson(object);
    if (result.otherKeys.containsKey('payload')) {
      var payload = result.otherKeys['payload'] as Map<String, dynamic>;

      return HereNowResult._(
          (payload['channels'] as Map<String, dynamic>).map((key, value) =>
              MapEntry(
                  key,
                  ChannelOccupancy.fromJson(
                      key, value as Map<String, dynamic>))),
          payload['total_occupancy'] as int,
          payload['total_channels'] as int);
    } else {
      return HereNowResult._({
        channelName: ChannelOccupancy.fromJson(channelName!, result.otherKeys)
      }, result.otherKeys['occupancy'] as int, 1);
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
      'uuid': keyset.uuid,
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
  final Set<String> channels;

  WhereNowResult._(this.channels);

  factory WhereNowResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);
    var payload = result.otherKeys['payload'] as Map<String, dynamic>;
    return WhereNowResult._(Set.from(payload['channels'] ?? []));
  }
}
