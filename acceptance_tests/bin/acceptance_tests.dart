import 'dart:io';

import 'package:dotenv/dotenv.dart' show load, env;
import 'package:gherkin/gherkin.dart';
import 'package:glob/glob.dart';

import 'package:acceptance_tests/acceptance_tests.dart';
import 'package:pubnub/core.dart';

part 'env.dart';

late final logger = TestLogger('Runner', debug: DEBUG);

late final serverAssembler = Assembler(
  'pubnub/service-contract-mock',
  branch: 'contract',
  outputPath: './mock-server',
  githubToken: GITHUB_TOKEN,
);

late final blueprint = MockServerBlueprint(
  serverPath: './mock-server',
  logger: logger,
);

late final gherkinConfig = PubNubConfiguration(
  featureFiles: Glob('mock-server/contract/features/**/*.feature'),
  blueprint: blueprint,
  logger: logger,
);

Future<void> main() async {
  load();

  if (!SKIP_ASSEMBLY &&
      (FORCE_ASSEMBLY || await serverAssembler.shouldAssemble)) {
    logger.info('Assembling mock server...');
    await serverAssembler.assemble();
  }

  if (!SKIP_BUILD && (FORCE_BUILD || await blueprint.shouldBuild)) {
    logger.info('Building mock server...');
    await blueprint.build();
  }

  try {
    await provideLogger(logger, () async {
      await GherkinRunner().execute(gherkinConfig);
    });
  } on GherkinTestRunFailedException {
    logger.fatal('Tests failed.');
  } on GherkinStepNotDefinedException {
    logger.fatal('Step not defined.');
  } finally {
    await blueprint.cleanup();
  }

  exit(0);
}
