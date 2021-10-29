import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '_utils.dart';
import '../../world.dart';

class StepThenTokenHasExpectedResourcePatternPermission
    extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(
      r'token pattern permission (READ|WRITE|MANAGE|DELETE|CREATE|GET|UPDATE|JOIN)');

  @override
  Future<void> executeStep(String access) async {
    var result = world.scenarioContext['resourcePatternPermissionBitValue'] &
        getBitValue(access);
    this.expect(result, equals(getBitValue(access)));
  }
}
