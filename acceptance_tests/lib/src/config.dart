import 'dart:io';

import 'package:gherkin/gherkin.dart';
import 'package:glob/glob.dart';

import 'hooks/mock_server_hook.dart';
import 'steps/steps.dart';
import 'parameters/parameters.dart';
import 'reporter.dart';
import 'world.dart';
import 'logger.dart';

class PubNubConfiguration extends TestConfiguration {
  @override
  final Iterable<Pattern> features;
  final TestLogger logger;
  final String tags;

  PubNubConfiguration(
      {required String featureFiles, required this.logger, required this.tags})
      : features = [Glob('**/*.feature')],
        featureFileMatcher =
            IoFeatureFileAccessor(workingDirectory: Directory(featureFiles));

  @override
  FeatureFileMatcher featureFileMatcher;

  @override
  var createWorld = PubNubWorld.create;

  var reporter = PubNubReporter();

  @override
  List<Reporter> get reporters => [reporter];

  @override
  var hooks = [MockServerHook()];

  @override
  var customStepParameterDefinitions = customParameters;

  @override
  var stepDefinitions = steps;

  @override
  ExecutionOrder get order => ExecutionOrder.alphabetical;

  @override
  String? get tagExpression => tags;
}
