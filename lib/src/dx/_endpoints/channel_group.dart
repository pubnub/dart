import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class ChannelGroupListChannelsParams extends Parameters {
  Keyset keyset;
  String name;

  ChannelGroupListChannelsParams(this.keyset, this.name);

  Request toRequest() {
    var pathSegments = [
      'v1',
      'channel-registration',
      'sub-key',
      keyset.subscribeKey,
      'channel-group',
      name
    ];

    var queryParameters = {'auth': keyset.authKey, 'uuid': keyset.uuid.value};

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class ChannelGroupListChannelsResult extends Result {
  String name;
  Set<String> channels;

  ChannelGroupListChannelsResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);
    var payload = result.otherKeys['payload'];

    name = payload['group'] as String;
    channels = (payload['channels'] as List<dynamic>).cast<String>().toSet();
  }
}

class ChannelGroupChangeChannelsParams extends Parameters {
  Keyset keyset;
  String name;
  Set<String> add;
  Set<String> remove;

  ChannelGroupChangeChannelsParams(this.keyset, this.name,
      {this.add, this.remove});

  Request toRequest() {
    var pathSegments = [
      'v1',
      'channel-registration',
      'sub-key',
      keyset.subscribeKey,
      'channel-group',
      name
    ];

    var queryParameters = {
      'auth': keyset.authKey,
      'uuid': keyset.uuid.value,
      if (add != null) 'add': add.join(','),
      if (remove != null) 'remove': remove.join(',')
    };

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class ChannelGroupChangeChannelsResult extends Result {
  ChannelGroupChangeChannelsResult.fromJson(Map<String, dynamic> object);
}

class ChannelGroupDeleteParams extends Parameters {
  Keyset keyset;
  String name;

  ChannelGroupDeleteParams(this.keyset, this.name);

  Request toRequest() {
    var pathSegments = [
      'v1',
      'channel-registration',
      'sub-key',
      keyset.subscribeKey,
      'channel-group',
      name,
      'remove'
    ];

    var queryParameters = {'auth': keyset.authKey, 'uuid': keyset.uuid.value};

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class ChannelGroupDeleteResult extends Result {
  ChannelGroupDeleteResult.fromJson(Map<String, dynamic> object);
}
