import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:gherkin/gherkin.dart';

import 'package:acceptance_tests/acceptance_tests.dart';
import 'package:xml/xml.dart';

late final logger = TestLogger('Runner', debug: false);

Future<void> main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  late final gherkinConfig = PubNubConfiguration(
    featureFiles:
        env['FEATURES_PATH'] ?? '../../service-contract-mock/contract/features',
    logger: logger,
    tags: 'not @skip and not @na=dart and not @beta',
  );

  var exitCode = 0;

  try {
    // await provideLogger(logger, () async {
    await GherkinRunner().execute(gherkinConfig);
    // });
  } on GherkinTestRunFailedException {
    // logger.fatal('Tests failed.');
    exitCode = 1;
  } on GherkinStepNotDefinedException {
    // logger.fatal('Step not defined.');
    exitCode = 1;
  } finally {
    var builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');

    gherkinConfig.reporter.result.build(builder);

    var document = builder.buildDocument();

    var report = File('report.xml');

    await report.writeAsString(document.toXmlString(pretty: true));

    gherkinConfig.reporter.printSummary();
  }

  exit(exitCode);
}
