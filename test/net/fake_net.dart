import 'dart:async';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/core/net/net.dart';
import 'package:pubnub/src/net/exceptions.dart';

class MockException extends PubNubException {
  MockException(String message) : super(message);
}

class FakeRequestHandler extends RequestHandler {
  Request request;

  final Completer<MockResponse> _contents = Completer();

  FakeRequestHandler(this.request, Mock mock) {
    var uri = Uri(
        pathSegments: request.pathSegments,
        queryParameters: request.queryParameters);

    var doesMethodMatch =
        mock.request.method.toUpperCase() == request.type.method.toUpperCase();

    var doesBodyMatch = mock.request.body == request.body;

    var doesUriMatch = mock.request.path == uri.toString();

    Future.microtask(() {
      if (doesMethodMatch && doesBodyMatch && doesUriMatch) {
        if (mock.response.status != 200) {
          _contents
              .completeError(PubNubRequestFailureException(mock.response.body));
        } else {
          _contents.complete(mock.response);
        }
      } else {
        var exceptionBody = '';
        if (!doesMethodMatch) {
          exceptionBody +=
              '\n* method:\n| EXPECTED: ${mock.request.method.toUpperCase()}\n| ACTUAL: ${request.type.method.toUpperCase()}';
        }
        if (!doesUriMatch) {
          exceptionBody +=
              '\n* uri:\n| EXPECTED: ${mock.request.path}\n| ACTUAL: ${uri.toString()}';
        }
        if (!doesBodyMatch) {
          exceptionBody +=
              '\n* body:\n| EXPECTED:\n${mock.request.body}\n| ACTUAL:\n${request.body}';
        }

        _contents.completeError(MockException(
            'mock request does not match the expected request$exceptionBody'));
      }
    });
  }

  @override
  Future<String> text() async {
    return (await _contents.future).body;
  }

  @override
  Future<Map<String, List<String>>> headers() async {
    return (await _contents.future).headers;
  }

  @override
  void cancel([dynamic reason]) {}
}

class MockRequest {
  final String method;
  final String path;
  final String body;
  final Map<String, List<String>> headers;

  const MockRequest(this.method, this.path,
      [this.headers = const {}, this.body]);
}

class MockResponse {
  final int status;
  final String body;
  final Map<String, List<String>> headers;

  const MockResponse(this.status, [this.headers = const {}, this.body]);
}

class Mock {
  final MockRequest request;
  final MockResponse response;

  Mock(this.request, this.response);
}

class MockBuilder {
  final List<Mock> _queue;
  final MockRequest _request;

  MockBuilder(this._queue, this._request);

  void then(
      {int status,
      Map<String, List<String>> headers,
      String body,
      MockResponse response}) {
    var mock = Mock(_request, response ?? MockResponse(status, headers, body));

    _queue.add(mock);
  }
}

List<Mock> _queue = [];

MockBuilder when(
    {String method,
    String path,
    Map<String, List<String>> headers,
    String body,
    MockRequest request}) {
  return MockBuilder(
      _queue, request ?? MockRequest(method, path, headers, body));
}

class FakeNetworkingModule implements NetworkingModule {
  FakeNetworkingModule() {
    _queue.clear();
  }

  @override
  Future<RequestHandler> handle(Request request) async {
    if (_queue.isEmpty) {
      throw MockException('set up the mock first');
    }

    return FakeRequestHandler(request, _queue.removeAt(0));
  }
}
