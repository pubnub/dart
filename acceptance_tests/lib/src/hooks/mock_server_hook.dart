import 'dart:convert';

import 'package:gherkin/gherkin.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
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

      await world.mockServer.start();

      await Future.delayed(Duration(seconds: 3));

      var res = await http.get(Uri.parse(
          'http://localhost:8090/init?__contract__script__=$contract'));

      world.logger.severe(
          '[Hook] Mock server initialized with "$contract": ${res.body}');

      await Future.delayed(Duration(seconds: 3));
    } on StateError {
      world.logger.fatal('[Hook] Mock server skipped.');
    }
  }

  @override
  Future<void> onAfterScenario(
    covariant PubNubConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    try {
      var tagParts = tags
          .firstWhere((element) => element.name.startsWith('@contract='))
          .name
          .split('=');

      var contract = tagParts.skip(1).first;

      var res = await http.get(Uri.parse('http://localhost:8090/expect'));
      var data = json.decode(res.body);

      var failedExp = data['expectations']['failed'] as List;
      var succeededExp = data['expectations']['succeeded'] as List;

      config.logger.severe(
          '[Hook] ${failedExp.length} failed expectations, ${succeededExp.length} succeeded expectations');
    } on StateError {
      config.logger.fatal('[Hook] Expectations skipped.');
    }
  }
}
