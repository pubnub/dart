import 'dart:convert';
import 'dart:io';

import 'hook_input.dart';

/// Blocks shell commands that spend minutes on live or nonexistent tooling.
///
/// Allowed test commands, from `pubnub/`:
/// * `dart test -P unit` and `derry test unit`
/// * `dart test` on one test file, including one integration file
/// * `dart test` on paths under `test/unit`
///
/// Denied:
/// * `dart test` with no preset and no file, and `dart test -P integration`
/// * `derry test`, `derry test default`, and `derry test integration`
/// * `build_runner` (the package does not use it)
/// * the acceptance-test runner
///
/// Anything else is allowed. A parse failure is also allowed, so a broken
/// hook does not freeze the agent.
Future<void> main() async {
  final command = (await readHookInput())?['command'];
  final reason = command is String ? denialReason(command) : null;
  if (reason == null) {
    stdout.writeln(jsonEncode({'permission': 'allow'}));
    return;
  }
  stdout.writeln(
    jsonEncode({
      'permission': 'deny',
      'user_message': reason,
      'agent_message': reason,
    }),
  );
}

const _unitHint =
    'From pubnub/, run `dart test -P unit`, `derry test unit`, or `dart test` '
    'on one test file.';

/// Returns the deny message for [command], or null when it may run.
String? denialReason(String command) {
  for (final segment in _segments(command)) {
    final reason = _denialForSegment(segment) ?? _denialForNested(segment);
    if (reason != null) return reason;
  }
  return null;
}

String? _denialForNested(String segment) {
  for (final token in _tokenize(segment)) {
    if (token == segment) continue;
    if (!_looksLikeInvocation(token)) continue;
    final reason = _denialForSegment(token);
    if (reason != null) return reason;
  }
  return null;
}

bool _looksLikeInvocation(String token) {
  final lower = token.toLowerCase();
  return lower.contains('dart') ||
      lower.contains('derry') ||
      lower.contains('build_runner') ||
      lower.contains('acceptance_tests');
}

List<String> _segments(String command) => command
    .split(RegExp(r'\r?\n|&&|\|\||;'))
    .map((segment) => segment.trim())
    .where((segment) => segment.isNotEmpty)
    .toList();

String? _denialForSegment(String segment) {
  final args = _tokenize(segment);
  if (args.isEmpty) return null;

  if (_invokesBuildRunner(args)) {
    return 'This package has no build_runner dependency. '
        'The build_runner step in pubnub/README.md is stale.';
  }
  if (_invokesAcceptanceTests(args)) {
    return 'Acceptance tests need the mock server and FEATURES_PATH. '
        'Do not start them from the agent.';
  }

  final derry = _derryTestScript(args);
  if (derry != null && derry != 'unit') {
    return '`derry test` runs the integration suite as well as unit tests. '
        '$_unitHint';
  }

  final testArgs = _dartTestArgs(args);
  if (testArgs == null) return null;
  if (_isHelp(testArgs)) return null;
  if (_testArgsAreNarrow(testArgs)) return null;

  if (_presets(testArgs).contains('integration')) {
    return '`dart test -P integration` runs the live suite. Integration tests '
        'time out after one minute each, and DataSync tests do not skip when '
        'DS_* keys are missing. $_unitHint';
  }
  return 'This command runs the live integration tests. $_unitHint';
}

bool _invokesBuildRunner(List<String> args) {
  final hasTool = args.any(_isDartExecutable);
  final hasRunner = args.any((arg) => arg.toLowerCase() == 'build_runner');
  return hasTool && hasRunner;
}

bool _invokesAcceptanceTests(List<String> args) {
  if (!args.any(_isDartExecutable)) return false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i].toLowerCase();
    if (arg == 'acceptance_tests' || arg.endsWith('/acceptance_tests.dart')) {
      return true;
    }
    if (arg.endsWith(r'\acceptance_tests.dart')) return true;
  }
  return false;
}

/// The script name after `derry test`, or null when this is not that command.
///
/// `derry test` with no script name is the `default` script.
String? _derryTestScript(List<String> args) {
  for (var i = 0; i < args.length - 1; i++) {
    if (!_isDerry(args[i]) || args[i + 1].toLowerCase() != 'test') continue;
    if (i + 2 >= args.length || args[i + 2].startsWith('-')) return 'default';
    return args[i + 2].toLowerCase();
  }
  return null;
}

/// Arguments after `dart test` / `dart run test` / `dart pub run test`.
List<String>? _dartTestArgs(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    if (!_isDartExecutable(args[i])) continue;
    var cursor = i + 1;
    if (cursor < args.length && args[cursor].toLowerCase() == 'pub') cursor++;
    if (cursor < args.length && args[cursor].toLowerCase() == 'run') cursor++;
    if (cursor < args.length && args[cursor].toLowerCase() == 'test') {
      return args.sublist(cursor + 1);
    }
  }
  return null;
}

const _valueFlags = {
  '-n',
  '--name',
  '-N',
  '--plain-name',
  '-t',
  '--tags',
  '-x',
  '--exclude-tags',
  '-p',
  '--platform',
  '-c',
  '--compiler',
  '-P',
  '--preset',
  '-j',
  '--concurrency',
  '--total-shards',
  '--shard-index',
  '--timeout',
  '--suite-load-timeout',
  '--coverage',
  '--coverage-path',
  '--coverage-package',
  '--test-randomize-ordering-seed',
  '-r',
  '--reporter',
  '--file-reporter',
};

bool _isHelp(List<String> args) =>
    args.contains('-h') ||
    args.contains('--help') ||
    args.contains('--version');

bool _testArgsAreNarrow(List<String> args) {
  final presets = _presets(args);
  final paths = _paths(args);
  final files = paths.where(_isDartFile).toList();
  final directories = paths.where((path) => !_isDartFile(path)).toList();
  final integrationPreset = presets.contains('integration');
  final onlyUnitPreset =
      presets.isNotEmpty && presets.every((preset) => preset == 'unit');

  if (files.length == 1 && directories.isEmpty) return true;
  if (integrationPreset) return false;
  if (paths.isEmpty) return onlyUnitPreset;
  if (directories.any(_isIntegrationSweep)) return false;
  if (files.any(_isIntegrationFile)) return false;
  if (paths.every(_isUnitPath)) return true;
  return false;
}

Set<String> _presets(List<String> args) {
  final presets = <String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--') break;
    if (arg.startsWith('-P') && arg.length > 2 && !arg.startsWith('--')) {
      presets.add(arg.substring(2));
      continue;
    }
    final name = arg.contains('=') ? arg.substring(0, arg.indexOf('=')) : arg;
    if (name != '-P' && name != '--preset') continue;
    final inline = arg.contains('=')
        ? arg.substring(arg.indexOf('=') + 1)
        : null;
    if (inline != null && inline.isNotEmpty) {
      presets.add(inline);
      continue;
    }
    if (i + 1 < args.length) presets.add(args[++i]);
  }
  return presets;
}

List<String> _paths(List<String> args) {
  final paths = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--') {
      paths.addAll(args.sublist(i + 1));
      break;
    }
    if (!arg.startsWith('-')) {
      paths.add(arg);
      continue;
    }
    if (arg.startsWith('-P') && !arg.startsWith('--') && arg.length > 2) {
      continue;
    }
    final name = arg.contains('=') ? arg.substring(0, arg.indexOf('=')) : arg;
    if (name == '-P' || name == '--preset') {
      if (!arg.contains('=') &&
          i + 1 < args.length &&
          !args[i + 1].startsWith('-')) {
        i++;
      }
      continue;
    }
    if (arg.contains('=')) continue;
    if (_valueFlags.contains(name) &&
        i + 1 < args.length &&
        !args[i + 1].startsWith('-')) {
      i++;
    }
  }
  return paths;
}

String _normalize(String path) =>
    path.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '');

bool _isDartFile(String path) =>
    _normalize(path).toLowerCase().endsWith('.dart');

bool _isUnitPath(String path) {
  final normalized = _stripTrailingSlash(_normalize(path));
  return normalized == 'test/unit' ||
      normalized.endsWith('/test/unit') ||
      normalized.startsWith('test/unit/') ||
      normalized.contains('/test/unit/');
}

bool _isIntegrationFile(String path) {
  if (!_isDartFile(path)) return false;
  final normalized = _normalize(path);
  return normalized.startsWith('test/integration/') ||
      normalized.contains('/test/integration/');
}

bool _isIntegrationSweep(String path) {
  if (_isDartFile(path)) return false;
  final normalized = _stripTrailingSlash(_normalize(path));
  return normalized == 'test/integration' ||
      normalized.endsWith('/test/integration') ||
      normalized.startsWith('test/integration/') ||
      normalized.contains('/test/integration/');
}

String _stripTrailingSlash(String path) =>
    path.endsWith('/') ? path.substring(0, path.length - 1) : path;

bool _isDartExecutable(String arg) {
  final name = arg.replaceAll('\\', '/').split('/').last.toLowerCase();
  return name == 'dart' || name == 'dart.exe' || name == 'dart.bat';
}

bool _isDerry(String arg) {
  final name = arg.replaceAll('\\', '/').split('/').last.toLowerCase();
  return name == 'derry' || name == 'derry.bat' || name == 'derry.cmd';
}

List<String> _tokenize(String command) {
  final args = <String>[];
  final current = StringBuffer();
  String? quote;
  for (final char in command.split('')) {
    if (quote != null) {
      if (char == quote) {
        quote = null;
      } else {
        current.write(char);
      }
      continue;
    }
    if (char == '"' || char == "'") {
      quote = char;
      continue;
    }
    if (char == ' ' || char == '\t') {
      if (current.isNotEmpty) {
        args.add(current.toString());
        current.clear();
      }
      continue;
    }
    current.write(char);
  }
  if (current.isNotEmpty) args.add(current.toString());
  return args;
}
