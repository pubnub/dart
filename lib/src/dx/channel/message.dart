import 'package:pubnub/src/core/core.dart';

class Message {
  dynamic contents;
  Timetoken timetoken;

  Message();

  factory Message.fromJson(Map<String, dynamic> object) {
    return Message()
      ..contents = object['message']
      ..timetoken = Timetoken(object['timetoken']);
  }
}
