import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class PamGrantTokenParams extends Parameters {
  final Keyset keyset;

  final String payload;
  final String timestamp;

  PamGrantTokenParams(this.keyset, this.payload, this.timestamp);

  @override
  Request toRequest() {
    var pathSegments = ['v3', 'pam', keyset.subscribeKey, 'grant'];
    var queryParameters = <String, String>{
      if (keyset.uuid != null) 'uuid': '${keyset.uuid.value}',
      'timestamp': timestamp,
    };

    return Request.post(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        body: payload);
    // TODO: fix me
    // signWith: (t, p, q, h, b) => computeV2Signature(keyset, t, p, q, b));
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
  final int ttl;
  final String timestamp;
  final Set<String> channels;
  final Set<String> channelGroups;
  final bool write;
  final bool read;
  final bool manage;
  final bool delete;

  PamGrantParams(this.keyset, this.authKeys, this.timestamp,
      {this.ttl,
      this.channels,
      this.channelGroups,
      this.write,
      this.read,
      this.manage,
      this.delete});

  @override
  Request toRequest() {
    var pathSegments = ['v2', 'auth', 'grant', 'sub-key', keyset.subscribeKey];

    var queryParameters = {
      if (authKeys != null && authKeys.isNotEmpty) 'auth': authKeys.join(','),
      if ((channels != null && channels.isNotEmpty))
        'channel': channels.join(','),
      if ((channelGroups != null && channelGroups.isNotEmpty))
        'channel-group': channelGroups.join(','),
      if (ttl != null) 'ttl': '$ttl',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}',
      'timestamp': timestamp,
      if (delete != null) 'd': delete ? '1' : '0',
      if (manage != null) 'm': manage ? '1' : '0',
      if (read != null) 'r': read ? '1' : '0',
      if (write != null) 'w': write ? '1' : '0',
    };
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
    //TODO: fix me
    // signWith: (t, p, q, h, b) => computeSignature(keyset, p, q));
  }
}

class Permission {
  final String channel;
  final String authKey;

  final bool read;
  final bool write;
  final bool manage;
  final bool delete;

  const Permission(this.channel, this.authKey,
      {this.read, this.write, this.manage, this.delete});
}

class PamGrantResult extends Result {
  final bool warning;
  final String message;
  final String level;
  final int ttl;

  final List<Permission> permissions;

  PamGrantResult(
      this.warning, this.message, this.level, this.ttl, this.permissions);

  factory PamGrantResult.fromJson(dynamic object) {
    var result = DefaultResult.fromJson(object);

    var hasWarning = result.otherKeys['warning'] != null &&
        result.otherKeys['warning'] == true;

    var payload = result.otherKeys['payload'];
    var permissions = <Permission>[];

    void addPermissions(String channel, Map auths) {
      for (var entry in auths.entries) {
        permissions.add(Permission(channel, entry.key,
            read: entry.value['r'] == 1 ? true : false,
            write: entry.value['w'] == 1 ? true : false,
            manage: entry.value['m'] == 1 ? true : false,
            delete: entry.value['d'] == 1 ? true : false));
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

    return PamGrantResult(hasWarning, result.message, payload['level'],
        payload['ttl'], permissions);
  }
}
