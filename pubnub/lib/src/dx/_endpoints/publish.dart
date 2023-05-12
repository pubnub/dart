import 'package:pubnub/core.dart';

class PublishParams extends Parameters {
  Keyset keyset;
  String channel;
  String message;

  String? meta;
  bool? storeMessage;
  int? ttl;
  bool? noReplication;

  PublishParams(this.keyset, this.channel, this.message,
      {this.storeMessage, this.ttl, this.noReplication});

  @override
  Request toRequest() {
    var pathSegments = [
      'publish',
      keyset.publishKey!,
      keyset.subscribeKey,
      '0',
      channel,
      '0',
      message
    ];

    var queryParameters = {
      if (storeMessage == true)
        'store': '1'
      else if (storeMessage == false)
        'store': '0',
      if (meta != null) 'meta': meta,
      if (noReplication != null && noReplication == true) 'norep': 'true',
      if (keyset.authKey != null) 'auth': keyset.authKey,
      'uuid': keyset.uuid.value,
      if (ttl != null) 'ttl': ttl.toString()
    };

    return Request.get(
        uri: Uri(
            pathSegments: pathSegments,
            queryParameters:
                queryParameters.isNotEmpty ? queryParameters : null));
  }
}

/// Result of publish endpoint call.
///
/// {@category Results}
class PublishResult extends Result {
  final bool isError;
  final String description;
  final int timetoken;

  PublishResult._(this.timetoken, this.description, this.isError);

  factory PublishResult.fromJson(dynamic object) {
    return PublishResult._(
        int.parse(object[2]), object[1], object[0] == 1 ? false : true);
  }
}
