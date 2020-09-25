import 'dart:convert' show base64, utf8;
import 'package:convert/convert.dart' show hex;

class CipherKey {
  final List<int> data;

  const CipherKey._(this.data);

  static CipherKey fromBase64(String key) {
    return CipherKey._(base64.decode(key).toList());
  }

  static CipherKey fromUtf8(String key) {
    return CipherKey._(utf8.encode(key));
  }

  static CipherKey fromHex(String key) {
    return CipherKey._(hex.decode(key));
  }

  static CipherKey fromList(List<int> key) {
    return CipherKey._(key);
  }
}
