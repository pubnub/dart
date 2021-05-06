@TestOn('vm')
@Tags(['integration'])

import 'dart:mirrors';
import 'dart:io';
import 'package:test/test.dart';

import 'package:pubnub/core.dart';
import 'package:pubnub/networking.dart';
import 'package:pubnub/src/networking/request_handler/io.dart';

final timeEndpoint = Uri.parse('/time/0');

class MockClient implements HttpClient {
  final _client = HttpClient();

  late InstanceMirror _mirror;

  MockClient() {
    _mirror = reflect(_client);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      if (invocation.memberName == #openUrl) {
        _invokedUris.add(invocation.positionalArguments[1]);
      }
    }

    return _mirror.delegate(invocation);
  }

  final List<Uri> _invokedUris = [];
  Uri get latestUri => _invokedUris.last;
}

void main() {
  late NetworkingModule networking;
  late MockClient mockClient;

  setUp(() {
    networking = NetworkingModule(origin: 'ps1.pndsn.com');
    mockClient = MockClient();
  });

  test('RequestHandler uses the custom origin', () async {
    var handler = await networking.handler() as RequestHandler;

    handler.client = mockClient;

    var request = Request.get(uri: timeEndpoint);

    await handler.response(request);

    expect(
        mockClient.latestUri.toString(),
        equals(
            'https://ps1.pndsn.com/time/0?pnsdk=PubNub-Dart%2F${Core.version}'));
  });

  test(
      'RequestHandler.response throws PubNubRequestCancelException if cancelled immediately',
      () async {
    var handler = await networking.handler();
    var request = Request.get(uri: timeEndpoint);

    var responseF = handler.response(request);

    var reason = Exception('cancel immediately');
    handler.cancel(reason);

    await expectLater(responseF, throwsA(isA<RequestCancelException>()));
  });

  test(
      'RequestHandler.response ignores cancellation after completing the request',
      () async {
    var handler = await networking.handler();
    var request = Request.get(uri: timeEndpoint);

    var response = await handler.response(request);

    handler.cancel(Exception('cancel after result'));

    expect(response.statusCode, equals(200));
  });

  test('RequestHandler.response times out properly', () async {
    var handler = await networking.handler();
    var request = Request.get(
      uri: Uri.parse(
          'https://ps.pndsn.com/v2/subscribe/demo/test/0?uuid=dart-test&tt=${DateTime.now().toTimetoken().value}'),
    );

    var responseF = handler.response(request);

    await expectLater(responseF, throwsA(isA<RequestTimeoutException>()));
  });

  test(
      'RequestHandler.response cancels properly after sending the request but before receiving the response',
      () async {
    var handler = await networking.handler();
    var request = Request.subscribe(
      uri: Uri.parse(
          'https://ps.pndsn.com/v2/subscribe/demo/test/0?uuid=dart-test&tt=${DateTime.now().toTimetoken().value}'),
    );

    var responseF = handler.response(request);

    await Future.delayed(Duration(seconds: 1), () => handler.cancel());

    await expectLater(responseF, throwsA(isA<RequestCancelException>()));
  });
}
