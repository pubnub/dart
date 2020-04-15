import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class GrantParams extends Parameters {
  Keyset keyset;

  Set<String> authKeys;
  int ttl;
  Set<String> channels;
  Set<String> channelGroups;
  bool write;
  bool read;
  bool manage;
  bool delete;

  GrantParams(this.keyset, this.authKeys,
      {this.ttl,
      this.channels,
      this.channelGroups,
      this.write,
      this.read,
      this.manage,
      this.delete});

  Request toRequest() {
    List<String> pathSegments = [
      'v2',
      'auth',
      'grant',
      'sub-key',
      keyset.subscribeKey
    ];
    Map<String, String> queryParameters = {
      if (authKeys != null && authKeys.length > 0) 'auth': authKeys.join(','),
      if ((channels != null && channels.length > 0))
        'channel': channels.join(','),
      if ((channelGroups != null && channelGroups.length > 0))
        'channel-group': channelGroups.join(','),
      'd': delete != null ? (delete ? '1' : '0') : '0',
      'm': manage != null ? (manage ? '1' : '0') : '0',
      'r': read != null ? (read ? '1' : '0') : '0',
      if (ttl != null) 'ttl': '$ttl',
      if (keyset.uuid != null) 'uuid': '${keyset.uuid}',
      'w': write != null ? (write ? '1' : '0') : '0'
    };
    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class GrantResult extends Result {
  int _status;
  String _message;
  Payload _payload;
  String _service;
  Map<String, dynamic> _error;

  int get status => _status;
  String get message => _message;
  Payload get payload => _payload;
  String get service => _service;
  Map<String, dynamic> get error => _error;

  GrantResult();

  factory GrantResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);

    return GrantResult()
      .._status = result.status
      .._payload = result.otherKeys['payload'] != null
          ? Payload.fromJson(result.otherKeys['payload'])
          : null
      .._service = result.otherKeys['service']
      .._message = result.otherKeys['message']
      .._error = result.error;
  }
}

class Payload {
  int _ttl;
  Auths _auths;
  String _subscribe_key;
  String _level;
  String _channel;

  int get ttl => _ttl;
  Auths get auths => _auths;
  String get subscribe_key => _subscribe_key;
  String get level => _level;
  String get channel => _channel;

  Payload();

  factory Payload.fromJson(dynamic object) {
    return Payload()
      .._ttl = object['ttl'] as int
      .._auths =
          object['auths'] == null ? null : Auths.fromJson(object['auths'])
      .._subscribe_key = object['subscribe_key'] as String
      .._level = object['level'] as String
      .._channel = object['channel'] as String;
  }
}

class Auths {
  Map<String, dynamic> _password;

  Map<String, dynamic> get password => _password;

  Auths();

  factory Auths.fromJson(dynamic object) =>
      Auths().._password = object['password'] as Map<String, dynamic>;
}

class GrantTokenParams extends Parameters {
  Keyset keyset;
  String grantObject;

  GrantTokenParams(this.keyset, this.grantObject);

  Request toRequest() {
    List<String> pathSegments = ['v3', 'pam', keyset.subscribeKey, 'grant'];

    return Request(
        type: RequestType.post,
        uri: Uri(pathSegments: pathSegments),
        body: grantObject);
  }
}

class GrantTokenResult extends Result {
  int _status;
  GrantTokenData _data;
  String _service;
  Map<String, dynamic> _error;

  int get status => _status;
  GrantTokenData get data => _data;
  String get service => _service;
  Map<String, dynamic> get error => _error;

  GrantTokenResult();

  factory GrantTokenResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return GrantTokenResult()
      .._status = result.status
      .._data =
          result.data != null ? GrantTokenData.fromJson(result.data) : null
      .._error = result.error
      .._service = result.otherKeys['service'];
  }
}

class GrantTokenData {
  String _message;
  String _token;

  String get message => _message;
  String get token => _token;

  GrantTokenData();

  factory GrantTokenData.fromJson(dynamic object) {
    return GrantTokenData()
      .._message = object['message'] as String
      .._token = object['token'] as String;
  }
}
