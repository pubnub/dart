@TestOn('vm')

import 'package:test/test.dart';

import 'package:pubnub/src/networking/request_handler/io_connection_manager.dart';

/// Decodes a built HTTP/2 header list into an ordered list of `name=value`
/// strings for easy assertions ([Header] has no value-equality).
List<String> _decode(Iterable headers) => headers
    .map((h) => '${String.fromCharCodes(h.name as List<int>)}='
        '${String.fromCharCodes(h.value as List<int>)}')
    .toList();

/// Returns just the (lower-cased) header names from a built header list.
List<String> _names(Iterable headers) => _decode(headers)
    .map((pair) => pair.substring(0, pair.indexOf('=')))
    .toList();

void main() {
  group('buildHttp2Path', () {
    test('defaults empty path to "/"', () {
      expect(buildHttp2Path(Uri.parse('https://example.com')), equals('/'));
    });

    test('includes the query string', () {
      expect(
        buildHttp2Path(Uri.parse('https://example.com/time/0?pnsdk=x&uuid=y')),
        equals('/time/0?pnsdk=x&uuid=y'),
      );
    });

    test('preserves an already-escaped query verbatim', () {
      // The request handler replaces "+" with "%20" before calling this, so the
      // helper must not re-encode.
      var uri =
          Uri.parse('https://example.com/p').replace(query: 'a=b%20c&d=e');
      expect(buildHttp2Path(uri), equals('/p?a=b%20c&d=e'));
    });
  });

  group('buildHttp2Headers', () {
    test('emits pseudo-headers first, lower-cased', () {
      var headers = _decode(buildHttp2Headers(
        method: 'GET',
        uri: Uri.parse('https://ps.pndsn.com/time/0?pnsdk=x'),
        headers: {'Accept': 'application/json'},
      ));

      expect(headers.take(4).map((p) => p.split('=').first).toList(),
          equals([':method', ':scheme', ':authority', ':path']));
      expect(headers[0], equals(':method=GET'));
      expect(headers[1], equals(':scheme=https'));
      expect(headers[2], equals(':authority=ps.pndsn.com'));
      expect(headers[3], equals(':path=/time/0?pnsdk=x'));
      // Regular header name is lower-cased.
      expect(headers.last, equals('accept=application/json'));
    });

    test('omits the port from :authority when it is the default 443', () {
      var headers = buildHttp2Headers(
        method: 'GET',
        uri: Uri.parse('https://h2.pubnubapi.com/x'),
        headers: const {},
      );
      expect(_decode(headers)[2], equals(':authority=h2.pubnubapi.com'));
    });

    test('includes a non-default port in :authority', () {
      var headers = buildHttp2Headers(
        method: 'GET',
        uri: Uri.parse('https://h2.pubnubapi.com:8443/x'),
        headers: const {},
      );
      expect(_decode(headers)[2], equals(':authority=h2.pubnubapi.com:8443'));
    });

    test('drops connection-specific headers', () {
      var names = _names(buildHttp2Headers(
        method: 'POST',
        uri: Uri.parse('https://ps.pndsn.com/publish'),
        headers: {
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=5',
          'Proxy-Connection': 'keep-alive',
          'Transfer-Encoding': 'chunked',
          'Upgrade': 'h2c',
          'Host': 'evil.example.com',
          'Content-Type': 'application/json',
        },
      ));

      expect(names, isNot(contains('connection')));
      expect(names, isNot(contains('keep-alive')));
      expect(names, isNot(contains('proxy-connection')));
      expect(names, isNot(contains('transfer-encoding')));
      expect(names, isNot(contains('upgrade')));
      expect(names, isNot(contains('host')));
      expect(names, contains('content-type'));
    });

    test('keeps "te: trailers" but drops other te values', () {
      var trailers = _names(buildHttp2Headers(
        method: 'GET',
        uri: Uri.parse('https://ps.pndsn.com/x'),
        headers: {'TE': 'trailers'},
      ));
      expect(trailers, contains('te'));

      var gzip = _names(buildHttp2Headers(
        method: 'GET',
        uri: Uri.parse('https://ps.pndsn.com/x'),
        headers: {'TE': 'gzip'},
      ));
      expect(gzip, isNot(contains('te')));
    });
  });
}
