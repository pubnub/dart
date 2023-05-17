import 'package:gherkin/gherkin.dart';
import 'package:xml/xml.dart';

import 'results.dart' as results;

abstract class Color {
  static const String NEUTRAL = '\u001b[33;34m'; // blue
  static const String DEBUG = '\u001b[1;30m'; // gray
  static const String FAIL = '\u001b[33;31m'; // red
  static const String WARN = '\u001b[33;10m'; // yellow
  static const String RESET = '\u001b[33;0m';
  static const String PASS = '\u001b[33;32m';
}

class PubNubReporter extends Reporter {
  results.TestResult result = results.TestResult();

  results.FeatureResult? currentFeature;
  results.ScenarioResult? currentScenario;

  int scenarioCount = 0;
  int passedScenarioCount = 0;

  XmlBuilder builder = XmlBuilder();

  @override
  Future<void> onTestRunStarted() async {
    // print('Started!');
  }

  @override
  Future<void> onTestRunFinished() async {
    // print(results);

    result.totalTests = scenarioCount;
    result.successfulTests = passedScenarioCount;
    result.failedTests = scenarioCount - passedScenarioCount;
  }

  @override
  Future<void> onFeatureStarted(StartedMessage message) async {
    // print('Feature started: ${message.name}.');
    // print('feature ${message.context} ${message.tags} ${message.target}');

    currentFeature = results.FeatureResult(message.name);
    result.features.add(currentFeature!);
  }

  @override
  Future<void> onScenarioStarted(StartedMessage message) async {
    // print('Scenario started: ${message.name}.');
    // print('scenario ${message.context} ${message.tags} ${message.target}');
    print(
        '\n${++scenarioCount}. ${message.name} ${Color.DEBUG}(${message.tags.map((tag) => tag.name).join(' ')})${Color.RESET}');

    currentScenario = results.ScenarioResult(message.name);
    currentFeature!.scenarios.add(currentScenario!);
  }

  @override
  Future<void> onStepStarted(StepStartedMessage message) async {
    // print('Step started: ${message.name}');
  }

  @override
  Future<void> onScenarioFinished(ScenarioFinishedMessage message) async {
    if (message.passed) {
      passedScenarioCount++;
    }

    currentScenario!.passed = message.passed;

    // print('Scenario ended: ${message.name} Passed? ${message.passed}');
  }

  @override
  Future<void> onStepFinished(StepFinishedMessage message) async {
    switch (message.result.result) {
      case StepExecutionResult.pass:
        print('\t${Color.PASS}[✓]${Color.RESET} ${message.name}');
        break;
      case StepExecutionResult.skipped:
        print('\t${Color.DEBUG}[-]${Color.RESET} ${message.name}');
        break;
      case StepExecutionResult.fail:
      case StepExecutionResult.error:
        print('\t${Color.FAIL}[x]${Color.RESET} ${message.name}');
        print('\t\t${message.result.resultReason}');
        break;
      case StepExecutionResult.timeout:
        print('\t${Color.WARN}[.]${Color.RESET} ${message.name}');
        break;
    }

    // print('Step finished: ${message.result.result}');
    currentScenario!.steps.add(results.StepResult.fromGherkin(message));
  }

  @override
  Future<void> onException(Object exception, StackTrace stackTrace) async {
    print('Exception happened! $exception $stackTrace');
    if (exception is Exception && currentScenario != null) {
      currentScenario!.exceptions.add(exception);
    }
  }

  @override
  Future<void> message(String message, MessageLevel level) async {
    if (level == MessageLevel.error) {
      print(message);
    }
  }

  void printSummary() {
    print('\n\nResults:');
    for (var feature in result.features) {
      for (var scenario in feature.scenarios) {
        if (!scenario.passed) {
          print('\n${Color.FAIL}[x]${Color.RESET} ${scenario.name}');
          for (var step in scenario.steps) {
            switch (step.result) {
              case StepExecutionResult.pass:
                print('\t${Color.PASS}[✓]${Color.RESET} ${step.name}');
                break;
              case StepExecutionResult.skipped:
                print('\t${Color.DEBUG}[-]${Color.RESET} ${step.name}');
                break;
              case StepExecutionResult.fail:
              case StepExecutionResult.error:
                print('\t${Color.FAIL}[x]${Color.RESET} ${step.name}');
                print('\t\t${step.reason?.replaceAll('\n', '\n\t\t')}');
                break;
              case StepExecutionResult.timeout:
                print('\t${Color.WARN}[.]${Color.RESET} ${step.name}');
                break;
            }
          }
        }
      }
    }

    print('');
    print('  $scenarioCount scenarios executed');
    print('${Color.PASS}✓${Color.RESET} $passedScenarioCount scenarios passed');
    print(
        '${Color.FAIL}x${Color.RESET} ${scenarioCount - passedScenarioCount} scenarios failed');
  }
}
