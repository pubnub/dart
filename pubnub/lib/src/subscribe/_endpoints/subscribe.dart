import 'package:pubnub/core.dart';

import '../extensions/keyset.dart';

class SubscribeParams extends Parameters {
  Keyset keyset;
  BigInt timetoken;

  Set<String>? channels;
  Set<String>? channelGroups;
  String? state;
  int? region;

  SubscribeParams(this.keyset, this.timetoken,
      {this.channels, this.channelGroups, this.state, this.region});

  @override
  Request toRequest() {
    String channelsString;

    if (channels == null || channels!.isEmpty) {
      channelsString = ',';
    } else {
      channelsString = channels!.join(',');
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
      if (channelGroups != null && channelGroups!.isNotEmpty)
        'channel-group': channelGroups!.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey,
      'uuid': keyset.uuid.value,
      if (keyset.filterExpression != null)
        'filter-expr': keyset.filterExpression,
      if (keyset.heartbeatInterval != null)
        'heartbeat': keyset.heartbeatInterval.toString()
    };

    return Request.subscribe(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class SubscribeResult extends Result {
  final Timetoken timetoken;
  final int region;
  final List<dynamic> messages;

  SubscribeResult._(this.timetoken, this.region, this.messages);

  factory SubscribeResult.fromJson(Map<String, dynamic> object) {
    return SubscribeResult._(
      Timetoken(BigInt.tryParse(object['t']?['t']) ?? BigInt.from(-1)),
      object['t']?['r'],
      object['m'],
    );
  }
}
