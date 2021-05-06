import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../logger.dart';

class MockServerBlueprint {
  final String serverPath;
  final TestLogger logger;

  MockServerBlueprint({required this.serverPath, required this.logger});

  Future<bool> get shouldBuild async {
    var nodeModulesExists =
        await Directory(p.join(serverPath, 'node_modules')).exists();
    var compiledIndexStat =
        await File(p.join(serverPath, 'dist/index.js')).stat();
    var sourceIndexStat = await File(p.join(serverPath, 'src/index.ts')).stat();

    return !nodeModulesExists ||
        !compiledIndexStat.modified.isAfter(sourceIndexStat.modified);
  }

  Future<void> build() async {
    var serverDir = Directory(serverPath);

    var installResult = await Process.run(
      'npm',
      ['install'],
      workingDirectory: serverDir.absolute.path,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (installResult.exitCode != 0) {
      throw Exception('npm install failed');
    }

    var buildResult = await Process.run(
      'npm',
      ['run', 'build'],
      workingDirectory: serverDir.absolute.path,
      stderrEncoding: utf8,
      stdoutEncoding: utf8,
    );

    if (buildResult.exitCode != 0) {
      throw Exception('npm build failed');
    }
  }

  final List<MockServer> _servers = [];

  MockServer create() {
    var server = MockServer(this);

    _servers.add(server);

    return server;
  }

  Future<void> cleanup() async {
    for (var server in _servers) {
      await server.stop();
    }
  }
}

class MockServer {
  final MockServerBlueprint blueprint;

  MockServer(this.blueprint);

  Process? process;

  bool get isRunning => process != null;

  Future<void> start() async {
    var serverDir = Directory(blueprint.serverPath);

    process = await Process.start('node', ['dist/index', 'consumer'],
        workingDirectory: serverDir.absolute.path);

    process?.stderr.listen((msg) {
      blueprint.logger.info('[Server] ' + utf8.decode(msg));
    });
    process?.stdout.listen((msg) {
      blueprint.logger.info('[Server] ' + utf8.decode(msg));
    });
  }

  Future<int> stop() async {
    if (isRunning) {
      var result2 = process!.kill(ProcessSignal.sigterm);
      blueprint.logger.info('killed? $result2');

      return await process!.exitCode;
    }

    return 0;
  }
}
