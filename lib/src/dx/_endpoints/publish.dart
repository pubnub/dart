import 'package:pubnub/src/core/core.dart';

class PublishParams extends Parameters {
  Keyset keyset;
  String channel;
  String message;

  bool storeMessage;
  int ttl;

  PublishParams(this.keyset, this.channel, this.message,
      {this.storeMessage, this.ttl});

  Request toRequest() {
    List<String> pathSegments = [
      'publish',
      keyset.publishKey,
      keyset.subscribeKey,
      '0',
      channel,
      '0'
    ];

    Map<String, String> queryParameters = {
      if (storeMessage == true)
        'store': '1'
      else if (storeMessage == false)
        'store': '0',
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (keyset.uuid != null) 'uuid': keyset.uuid.value,
      if (ttl != null) 'ttl': ttl.toString()
    };

    return Request(
        type: RequestType.post,
        uri: Uri(
            pathSegments: pathSegments,
            queryParameters:
                queryParameters.length > 0 ? queryParameters : null),
        body: message);
  }
}

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
