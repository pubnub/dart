import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/subscribe/extensions/keyset.dart';

class SubscribeParams extends Parameters {
  Keyset keyset;
  int timetoken;

  Set<String> channels;
  Set<String> channelGroups;
  String state;
  int region;
  int heartbeat;

  SubscribeParams(this.keyset, this.timetoken,
      {this.channels,
      this.channelGroups,
      this.state,
      this.heartbeat,
      this.region});

  @override
  Request toRequest() {
    String channelsString;

    if (channels == null || channels.isEmpty) {
      channelsString = ',';
    } else {
      channelsString = channels.join(',');
    }

    var pathSegments = [
      'v2',
      'subscribe',
      keyset.subscribeKey,
      channelsString,
      '0'
    ];

    var queryParameters = {
      'tt': timetoken.toString(),
      if (state != null) 'state': state,
      if (region != null) 'tr': region.toString(),
      if (channelGroups != null && channelGroups.isNotEmpty)
        'channel-group': channelGroups.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (keyset.uuid != null) 'uuid': keyset.uuid.value,
      if (keyset.filterExpression != null)
        'filter-expr': keyset.filterExpression
    };

    return Request(RequestType.subscribe, pathSegments,
        queryParameters: queryParameters,
        headers: {'Content-Type': 'application/json'});
  }
}

class SubscribeResult extends Result {
  Timetoken timetoken;
  int region;
  List<dynamic> messages;

  SubscribeResult();

  SubscribeResult.fromJson(Map<String, dynamic> object)
      : timetoken = Timetoken(int.tryParse(object['t']['t'])),
        region = object['t']['r'] as int,
        messages = object['m'];
}
