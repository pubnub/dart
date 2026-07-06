@TestOn('vm')
@Tags(['integration'])

import 'dart:io';

import 'package:test/test.dart';

import 'package:pubnub/core.dart';
import 'package:pubnub/networking.dart';

final timeEndpoint = Uri.parse('/time/0');

Future<String?> alpnProtocol(String host) async {
  final socket = await SecureSocket.connect(host, 443,
      supportedProtocols: const ['h2', 'http/1.1']);
  final protocol = socket.selectedProtocol;
  await socket.close();
  socket.destroy();
  return protocol;
}

void main() {
  test('h2.pubnubapi.com negotiates HTTP/2 via ALPN', () async {
    expect(await alpnProtocol('h2.pubnubapi.com'), equals('h2'));
  });

  test('request over the HTTP/2 origin succeeds', () async {
    var module = NetworkingModule(origin: 'h2.pubnubapi.com');
    var handler = await module.handler();

    var response = await handler.response(Request.get(uri: timeEndpoint));

    expect(response.statusCode, equals(200));
    // /time/0 returns a single-element JSON array with the current timetoken.
    expect(response.text.trim(), startsWith('['));
  });

  test('falls back to HTTP/1.1 when the origin does not support h2', () async {
    var module = NetworkingModule(origin: 'ps.pndsn.com');
    var handler = await module.handler();

    var response = await handler.response(Request.get(uri: timeEndpoint));

    expect(response.statusCode, equals(200));
  });

  test('enableHttp2: false forces the HTTP/1.1 path', () async {
    var module =
        NetworkingModule(origin: 'h2.pubnubapi.com', enableHttp2: false);
    var handler = await module.handler();

    var response = await handler.response(Request.get(uri: timeEndpoint));

    expect(response.statusCode, equals(200));
  });

  test('concurrent requests multiplex over a shared HTTP/2 connection',
      () async {
    var module = NetworkingModule(origin: 'h2.pubnubapi.com');

    var handlerA = await module.handler();
    var handlerB = await module.handler();

    var responses = await Future.wait([
      handlerA.response(Request.get(uri: timeEndpoint)),
      handlerB.response(Request.get(uri: timeEndpoint)),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(equals(200)));
  });

  test('cancelling an HTTP/2 stream throws RequestCancelException', () async {
    var module = NetworkingModule(origin: 'h2.pubnubapi.com');
    var handler = await module.handler();

    var responseF = handler.response(Request.subscribe(
      uri: Uri.parse(
          '/v2/subscribe/demo/test/0?uuid=dart-test&tt=${DateTime.now().toTimetoken().value}'),
    ));

    await Future.delayed(Duration(seconds: 1), () => handler.cancel());

    await expectLater(responseF, throwsA(isA<RequestCancelException>()));
  });

  test('terminating one HTTP/2 stream does not affect a sibling stream',
      () async {
    var module = NetworkingModule(origin: 'h2.pubnubapi.com');

    var subscribeHandler = await module.handler();
    var timeHandler = await module.handler();

    // Long-poll subscribe that we will cancel mid-flight.
    var subscribeF = subscribeHandler.response(Request.subscribe(
      uri: Uri.parse(
          '/v2/subscribe/demo/test/0?uuid=dart-test&tt=${DateTime.now().toTimetoken().value}'),
    ));

    // A sibling request that must still complete successfully.
    var timeF = timeHandler.response(Request.get(uri: timeEndpoint));

    await Future.delayed(Duration(milliseconds: 500), subscribeHandler.cancel);

    await expectLater(subscribeF, throwsA(isA<RequestCancelException>()));
    var timeResponse = await timeF;
    expect(timeResponse.statusCode, equals(200));
  });
}
