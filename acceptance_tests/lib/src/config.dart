import 'package:gherkin/gherkin.dart';

import 'mock_server/mock_server.dart';
import 'hooks/mock_server_hook.dart';
import 'steps/steps.dart';
import 'world.dart';
import 'logger.dart';

class PubNubConfiguration extends TestConfiguration {
  @override
  final Iterable<Pattern> features;
  final TestLogger logger;

  PubNubConfiguration(
      {required Pattern featureFiles,
      required this.blueprint,
      required this.logger})
      : features = [featureFiles];

  final MockServerBlueprint blueprint;

  @override
  var createWorld = PubNubWorld.create;

  @override
  var reporters = [
    // StdoutReporter(MessageLevel.warning),
    TestRunSummaryReporter(),
    ProgressReporter()
  ];

  @override
  var hooks = [MockServerHook()];

  @override
  var stepDefinitions = steps;
}
