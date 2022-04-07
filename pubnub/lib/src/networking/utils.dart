const _forbiddenHeaders = [
  'Accept-Charset',
  'Accept-Encoding',
  'Access-Control-Request-Headers',
  'Access-Control-Request-Method',
  'Connection',
  'Content-Length',
  'Cookie',
  'Date',
  'DNT',
  'Expect',
  'Feature-Policy',
  'Host',
  'Keep-Alive',
  'Origin',
  'Proxy-',
  'Sec-',
  'Referer',
  'TE',
  'Trailer',
  'Transfer-Encoding',
  'Upgrade',
  'Via',
];

bool isHeaderForbidden(String header) {
  return _forbiddenHeaders
      .any((element) => element.matchAsPrefix(header) != null);
}
