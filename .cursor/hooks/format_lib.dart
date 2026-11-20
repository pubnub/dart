import 'dart:io';

import 'hook_input.dart';

/// Formats a file the agent just wrote, when it belongs to the published SDK.
///
/// CI fails `dart format -o none --set-exit-if-changed lib` inside `pubnub/`.
/// Formatting that one file here avoids a follow-up turn spent only on style.
/// Tests, `pubnub_flutter`, and other packages are left untouched.
Future<void> main() async {
  final input = await readHookInput();
  final filePath = input?['file_path'];
  if (filePath is! String || !_isPubnubLibDart(filePath)) return;
  if (!File(filePath).existsSync()) return;

  final result = await Process.run(Platform.resolvedExecutable, [
    'format',
    filePath,
  ]);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
  }
}

bool _isPubnubLibDart(String filePath) {
  final parts = filePath.replaceAll('\\', '/').split('/');
  if (!parts.last.toLowerCase().endsWith('.dart')) return false;
  for (var i = 0; i < parts.length - 1; i++) {
    if (parts[i].toLowerCase() == 'pubnub' &&
        parts[i + 1].toLowerCase() == 'lib') {
      return true;
    }
  }
  return false;
}
