import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class Assembler {
  final String repository;
  final String outputPath;
  final String githubToken;
  final String branch;

  Assembler(this.repository,
      {this.branch = 'master',
      required this.githubToken,
      required this.outputPath});

  Future<bool> get shouldAssemble async {
    var outputDir = Directory(outputPath);

    var exists = await outputDir.exists();

    if (!exists) {
      return true;
    }

    var stat = await outputDir.stat();

    var diff = DateTime.now().difference(stat.modified);

    return diff.inDays > 1;
  }

  Future<void> assemble() async {
    var outputDir = Directory(outputPath);

    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }

    var request = await HttpClient().getUrl(
        Uri.parse('https://api.github.com/repos/$repository/zipball/$branch'));

    request.headers.set('Authorization', 'token $githubToken');

    var response = await request.close();

    var bytes = await response.fold<List<int>>([], (a, b) => [...a, ...b]);

    var archive = ZipDecoder().decodeBytes(bytes);

    await outputDir.create(recursive: true);

    for (final file in archive.files) {
      if (file.isFile) {
        var filepath = p.join(
            outputDir.path, p.relative(file.name, from: archive.first.name));

        var output = await File(filepath).create(recursive: true);
        await output.writeAsBytes(file.content as List<int>);
      }
    }
  }
}
