import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class ChannelGroupListChannelsParams extends Parameters {
  Keyset keyset;
  String name;

  ChannelGroupListChannelsParams(this.keyset, this.name);

  @override
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
      if (keyset.authKey != null) 'auth': keyset.authKey,
      'uuid': keyset.uuid.value
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of list channel groups channels endpoint call.
///
/// {@category Results}
class ChannelGroupListChannelsResult extends Result {
  /// Channel group name.
  final String name;

  /// Channel group channels.
  final Set<String> channels;

  ChannelGroupListChannelsResult(this.name, this.channels);

  /// @nodoc
  factory ChannelGroupListChannelsResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultResult.fromJson(object);
    var payload = result.otherKeys['payload'];

    return ChannelGroupListChannelsResult(payload['group'] as String,
        (payload['channels'] as List<dynamic>).cast<String>().toSet());
  }
}

class ChannelGroupChangeChannelsParams extends Parameters {
  Keyset keyset;
  String name;
  Set<String>? add;
  Set<String>? remove;

  ChannelGroupChangeChannelsParams(this.keyset, this.name,
      {this.add, this.remove});

  @override
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
      if (keyset.authKey != null) 'auth': keyset.authKey,
      'uuid': keyset.uuid.value,
      'add': add?.join(','),
      'remove': remove?.join(',')
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of add or remove channels of channel group endpoint call.
///
/// {@category Results}
class ChannelGroupChangeChannelsResult extends Result {
  /// @nodoc
  ChannelGroupChangeChannelsResult.fromJson(Map<String, dynamic> object);
}

class ChannelGroupDeleteParams extends Parameters {
  Keyset keyset;
  String name;

  ChannelGroupDeleteParams(this.keyset, this.name);

  @override
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

    var queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
      'uuid': keyset.uuid.value
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of remove channel group endpoint call.
///
/// {@category Results}
class ChannelGroupDeleteResult extends Result {
  /// @nodoc
  ChannelGroupDeleteResult.fromJson(Map<String, dynamic> object);
}
