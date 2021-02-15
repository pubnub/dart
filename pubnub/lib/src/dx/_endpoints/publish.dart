import 'package:pubnub/core.dart';

class PublishParams extends Parameters {
  Keyset keyset;
  String channel;
  String message;

  String meta;
  bool storeMessage;
  int ttl;

  PublishParams(this.keyset, this.channel, this.message,
      {this.storeMessage, this.ttl});

  @override
  Request toRequest() {
    var pathSegments = [
      'publish',
      keyset.publishKey,
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
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (keyset.uuid != null) 'uuid': keyset.uuid.value,
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
  bool isError;
  String description;
  int timetoken;

  PublishResult();

  factory PublishResult.fromJson(dynamic object) {
    return PublishResult()
      ..timetoken = int.tryParse(object[2])
      ..description = object[1]
      ..isError = object[0] == 1 ? false : true;
  }
}
