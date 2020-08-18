import 'dart:convert' show utf8;
import 'package:xml/xml.dart' show XmlDocument;
import 'package:meta/meta.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/net/exceptions.dart';

Future<R> customFlow<P extends Parameters, R>(
    {@required ILogger logger,
    @required Core core,
    @required P params,
    @required Serialize<R> serialize}) async {
  var request = params.toRequest();

  try {
    var handler = await core.networking.handleCustomRequest(request);

    var response = await handler.response();
    var headers = await handler.headers();

    var result = serialize(response, headers);

    return result;
  } on PubNubRequestFailureException catch (exception) {
    var responseData = exception.responseData;
    if (responseData.data != null) {
      var details = utf8.decode(exception.responseData.data);
      var messageNode =
          XmlDocument.parse(details).rootElement.getElement('Message');
      if (messageNode != null) {
        details = messageNode.text;
      }
      throw PubNubException(
          '${responseData.statusCode}\n${responseData.statusMessage}\n${exception.message}\n$details');
    }
    throw PubNubException('${responseData.statusCode}');
  }
}
