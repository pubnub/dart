import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class PamGrantTokenParams extends Parameters {
  final Keyset keyset;

  final String payload;

  PamGrantTokenParams(this.keyset, this.payload);

  @override
  Request toRequest() {
    var pathSegments = ['v3', 'pam', keyset.subscribeKey, 'grant'];
    var queryParameters = <String, String>{
      'uuid': '${keyset.uuid.value}',
    };

    return Request.post(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        body: payload);
  }
}

class PamGrantTokenResult extends Result {
  final String message;
  final String token;

  PamGrantTokenResult._(this.message, this.token);

  factory PamGrantTokenResult.fromJson(dynamic object) {
    var result = DefaultResult.fromJson(object);
    var data = result.otherKeys['data'];

    return PamGrantTokenResult._(data['message'], data['token']);
  }
}

class PamGrantParams extends Parameters {
  final Keyset keyset;

  final Set<String> authKeys;
  final int? ttl;
  final Set<String>? channels;
  final Set<String>? channelGroups;
  final Set<String>? uuids;
  final bool? write;
  final bool? read;
  final bool? manage;
  final bool? delete;
  final bool? get;
  final bool? update;
  final bool? join;

  PamGrantParams(this.keyset, this.authKeys,
      {this.ttl,
      this.channels,
      this.channelGroups,
      this.uuids,
      this.write,
      this.read,
      this.manage,
      this.delete,
      this.get,
      this.update,
      this.join});

  @override
  Request toRequest() {
    var pathSegments = ['v2', 'auth', 'grant', 'sub-key', keyset.subscribeKey];

    var queryParameters = {
      if (authKeys.isNotEmpty) 'auth': authKeys.join(','),
      if ((channels != null && channels!.isNotEmpty))
        'channel': channels!.join(','),
      if ((channelGroups != null && channelGroups!.isNotEmpty))
        'channel-group': channelGroups!.join(','),
      if (uuids != null && uuids!.isNotEmpty) 'target-uuid': uuids!.join(','),
      if (ttl != null) 'ttl': '$ttl',
      'uuid': '${keyset.uuid}',
      if (delete != null) 'd': delete! ? '1' : '0',
      if (manage != null) 'm': manage! ? '1' : '0',
      if (read != null) 'r': read! ? '1' : '0',
      if (write != null) 'w': write! ? '1' : '0',
      if (get != null) 'g': get! ? '1' : '0',
      if (update != null) 'u': update! ? '1' : '0',
      if (join != null) 'j': join! ? '1' : '0'
    };
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class Permission {
  final String? channel;
  final String? uuid;
  final String authKey;

  final bool? read;
  final bool? write;
  final bool? manage;
  final bool? delete;
  final bool? get;
  final bool? update;
  final bool? join;

  const Permission(this.authKey,
      {this.channel,
      this.uuid,
      this.read,
      this.write,
      this.manage,
      this.delete,
      this.get,
      this.join,
      this.update});
}

class PamGrantResult extends Result {
  final bool warning;
  final String message;
  final String level;
  final int ttl;

  final List<Permission> permissions;

  PamGrantResult._(
      this.warning, this.message, this.level, this.ttl, this.permissions);

  factory PamGrantResult.fromJson(dynamic object) {
    var result = DefaultResult.fromJson(object);

    var hasWarning = result.otherKeys['warning'] != null &&
        result.otherKeys['warning'] == true;

    var payload = result.otherKeys['payload'];
    var permissions = <Permission>[];

    void addPermissions(String channel, Map auths) {
      for (var entry in auths.entries) {
        permissions.add(Permission(entry.key,
            channel: channel,
            read: entry.value['r'] == 1 ? true : false,
            write: entry.value['w'] == 1 ? true : false,
            manage: entry.value['m'] == 1 ? true : false,
            delete: entry.value['d'] == 1 ? true : false,
            update: entry.value['u'] == 1 ? true : false,
            join: entry.value['j'] == 1 ? true : false,
            get: entry.value['g'] == 1 ? true : false));
      }
    }

    if (payload['channel'] != null) {
      String channel = payload['channel'];

      addPermissions(channel, payload['auths']);
    }

    if (payload['channels'] != null) {
      var channels = payload['channels'];

      for (var entry in channels.entries) {
        addPermissions(entry.key, entry.value['auths']);
      }
    }

    void addUuidPermissions(String uuid, Map auths) {
      for (var entry in auths.entries) {
        permissions.add(Permission(entry.key,
            uuid: uuid,
            read: entry.value['r'] == 1 ? true : false,
            write: entry.value['w'] == 1 ? true : false,
            manage: entry.value['m'] == 1 ? true : false,
            delete: entry.value['d'] == 1 ? true : false,
            update: entry.value['u'] == 1 ? true : false,
            join: entry.value['j'] == 1 ? true : false,
            get: entry.value['g'] == 1 ? true : false));
      }
    }

    if (payload['uuids'] != null) {
      var uuids = payload['uuids'];
      for (var entry in uuids.entries) {
        addUuidPermissions(entry.key, entry.value['auths']);
      }
    }

    return PamGrantResult._(hasWarning, result.message!, payload['level'],
        payload['ttl'], permissions);
  }
}

class PamRevokeTokenParams extends Parameters {
  final Keyset keyset;

  final String token;

  PamRevokeTokenParams(this.keyset, this.token);

  @override
  Request toRequest() {
    var pathSegments = ['v3', 'pam', keyset.subscribeKey, 'grant', '$token'];

    return Request.delete(uri: Uri(pathSegments: pathSegments));
  }
}

/// Result of Revoke Token endpoint call.
///
/// {@category Results}
/// {@category PAM v3}
class PamRevokeTokenResult extends Result {
  PamRevokeTokenResult._();

  /// @nodoc
  factory PamRevokeTokenResult.fromJson(dynamic object) =>
      PamRevokeTokenResult._();
}
