import 'package:test/test.dart';

import 'package:pubnub/src/networking/utils.dart';

void main() {
  group('Networking utils', () {
    test('isHeaderForbidden should return true for Content-Length header', () {
      expect(isHeaderForbidden('Content-Length'), equals(true));
    });

    test('isHeaderForbidden should return true for any Sec- or Proxy- header',
        () {
      expect(isHeaderForbidden('Sec-Test-1'), equals(true));
      expect(isHeaderForbidden('Sec-Random-2'), equals(true));
      expect(isHeaderForbidden('Proxy-Whatever'), equals(true));
    });

    test(
        'isHeaderForbidden should return false for any other header not specified',
        () {
      expect(isHeaderForbidden('X-Custom-Header'), equals(false));
      expect(isHeaderForbidden('Content-Type'), equals(false));
    });
  });
}
