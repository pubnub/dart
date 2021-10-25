import 'dart:convert';

import 'package:gherkin/gherkin.dart';
import 'package:http/http.dart' as http;

import '../world.dart';

class MockServerHook extends Hook {
  @override
  Future<void> onAfterScenarioWorldCreated(
    covariant PubNubWorld world,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    try {
      var tagParts = tags
          .firstWhere((element) => element.name.startsWith('@contract='))
          .name
          .split('=');

      var contract = tagParts.skip(1).first;

      // await Future.delayed(Duration(seconds: 3));

      var res = await http.get(Uri.parse(
          'http://localhost:8090/init?__contract__script__=$contract'));

      // check for 200 response and fail scenario if not 200

      if (res.statusCode != 200) {
        throw Exception('Mock server is not ready for initialization.');
      }
      // ignore: empty_catches
    } on StateError {}
  }

  int myData = 0;

  @override
  Future<StepResult?> onAfterStep(
      covariant PubNubWorld world, String step, StepResult stepResult) async {
    // print(
    //     'Hook step: $step, result: ${stepResult.result} ${stepResult.resultReason}');

    if (stepResult.result == StepExecutionResult.pass) {
      // await Future.delayed(Duration(seconds: 1));
      var res = await http.get(Uri.parse('http://localhost:8090/expect'));
      var data = json.decode(res.body);

      var failedExp = data['expectations']['failed'] as List;
      // var succeededExp = data['expectations']['succeeded'] as List;
      // var pendingExp = data['expectations']['pending'] as List;

      // world.logger.severe(
      //     '[Hook] x ${failedExp.length}, . ${pendingExp.length}, v ${succeededExp.length}');

      if (failedExp.isNotEmpty) {
        return StepResult(stepResult.elapsedMilliseconds,
            StepExecutionResult.fail, 'Failed expectations: $failedExp.');
      }
    }

    return stepResult;
  }
}
