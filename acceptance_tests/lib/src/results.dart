import 'package:gherkin/gherkin.dart' as gherkin;
import 'package:xml/xml.dart';

abstract class Buildable {
  void build(XmlBuilder builder);
}

class TestResult implements Buildable {
  int? totalTests;
  int? successfulTests;
  int? failedTests;
  int? skippedTests;
  int? erroredTests;

  List<FeatureResult> features = [];

  @override
  void build(XmlBuilder builder) {
    builder.element('testsuites', nest: () {
      if (totalTests != null) {
        builder.attribute('tests', totalTests!);
      }

      if (failedTests != null) {
        builder.attribute('failed', failedTests!);
      }

      for (var feature in features) {
        feature.build(builder);
      }
    });
  }
}

class FeatureResult implements Buildable {
  final String name;

  List<ScenarioResult> scenarios = [];

  FeatureResult(this.name);

  @override
  void build(XmlBuilder builder) {
    builder.element('testsuite', nest: () {
      builder.attribute('name', name);

      for (var scenario in scenarios) {
        scenario.build(builder);
      }
    });
  }
}

class ScenarioResult implements Buildable {
  final String name;

  bool passed = false;
  List<StepResult> steps = [];
  List<Exception> exceptions = [];

  ScenarioResult(this.name);

  @override
  void build(XmlBuilder builder) {
    builder.element('testcase', nest: () {
      builder.attribute('name', name);
      builder.attribute('steps', steps.length);

      for (var fail in steps
          .where((step) => step.result == gherkin.StepExecutionResult.fail)) {
        builder.element('failure', nest: () {
          builder.attribute('message', fail.reason ?? 'Unspecified reason');
        });
      }

      for (var error in steps
          .where((step) => step.result == gherkin.StepExecutionResult.error)) {
        builder.element('error', nest: () {
          builder.attribute('message', error.reason ?? 'Unspecified reason');
        });
      }

      for (var exception in exceptions) {
        builder.element('error', nest: () {
          builder.attribute('message', exception.toString());
        });
      }
    });
  }
}

class StepResult implements Buildable {
  final String name;
  final gherkin.StepExecutionResult result;
  final String? reason;
  final int duration;

  StepResult(this.name, this.result, {required this.duration, this.reason});

  factory StepResult.fromGherkin(gherkin.StepFinishedMessage message) {
    return StepResult(message.name, message.result.result,
        duration: message.result.elapsedMilliseconds,
        reason: message.result.resultReason);
  }

  @override
  void build(XmlBuilder builder) {}
}
