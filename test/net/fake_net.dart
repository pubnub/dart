import 'dart:async';

import 'package:pubnub/src/core/net/net.dart';
import 'package:pubnub/src/net/exceptions.dart';

class FakeRequestHandler extends RequestHandler {
  Request request;

  Completer<FakeResult> _contents = Completer();

  FakeRequestHandler(this.request, Map<String, dynamic> result) {
    Future.delayed(Duration(milliseconds: 100), () {
      if (result['method'] == request.type.method &&
          ((request.body == null && result['body'] == null) ||
              request.body == result['body']) &&
          request.uri.toString() == result['path']) {
        if (result['exception'] != null) {
          _contents.completeError(result['exception']);
        } else {
          _contents.complete(result['result']);
        }
      } else {
        print('''
Expected - actual
${result['method']} - ${request.type.method}
${result['path']} - ${request.uri}
${result['body']} - ${request.body}
''');
        _contents.completeError(PubNubRequestOtherException(result));
      }
    });
  }

  Future<String> text() async {
    return (await _contents.future).response;
  }

  Future<Map<String, List<String>>> headers() async {
    return (await _contents.future).headers;
  }

  void cancel([dynamic reason]) {}
}

List<Map<String, dynamic>> _queue = [];

class FakeResult {
  String response;
  Map<String, List<String>> headers = {};

  FakeResult(this.response, [this.headers]);
}

void when(
    {String method,
    String path,
    String body,
    FakeResult then,
    Exception throws}) {
  _queue.add({
    'method': method,
    'path': path,
    'body': body,
    'result': then,
    'exception': throws
  });
}

class FakeNetworkingModule implements NetworkingModule {
  Future<RequestHandler> handle(Request request) async {
    if (_queue.length == 0) {
      throw Exception('Please set up the fake response first.');
    }

    return FakeRequestHandler(request, _queue.removeAt(0));
  }
}
