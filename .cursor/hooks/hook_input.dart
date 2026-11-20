import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Reads the JSON object Cursor writes to a hook's stdin.
///
/// On Windows the desktop app runs hooks through PowerShell, which sometimes
/// delivers that payload as UTF-16. Both encodings are accepted.
Future<Map<String, dynamic>?> readHookInput() async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stdin) {
    builder.add(chunk);
  }
  final bytes = builder.takeBytes();
  if (bytes.isEmpty) return null;

  Object? decoded;
  try {
    decoded = jsonDecode(_decodeHookBytes(bytes));
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  return Map<String, dynamic>.from(decoded);
}

String _decodeHookBytes(List<int> bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return String.fromCharCodes(_utf16CodeUnits(bytes.sublist(2)));
  }
  if (_looksLikeUtf16Le(bytes)) {
    return String.fromCharCodes(_utf16CodeUnits(bytes));
  }
  return utf8.decode(bytes, allowMalformed: true);
}

bool _looksLikeUtf16Le(List<int> bytes) {
  if (bytes.length < 8 || bytes.length.isOdd) return false;
  var zeros = 0;
  for (var i = 1; i < bytes.length; i += 2) {
    if (bytes[i] == 0) zeros++;
  }
  return zeros > bytes.length ~/ 4;
}

List<int> _utf16CodeUnits(List<int> bytes) {
  final codes = <int>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    codes.add(bytes[i] | (bytes[i + 1] << 8));
  }
  return codes;
}
