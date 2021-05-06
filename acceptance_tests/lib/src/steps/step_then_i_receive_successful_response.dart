import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepThenIReceiveSuccessfulResponse extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I receive successful response');

  @override
  Future<void> executeStep() async {
    this.expect(world.latestResultType, isNotNull);

    switch (world.latestResultType!) {
      case 'publish':
        var result = world.latestResult as PublishResult;
        this.expect(result.isError, equals(false));
        break;
    }
  }
}
