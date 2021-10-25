import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepThenResponseContainsPaginationInfo
    extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'the response contains pagination info');

  @override
  Future<void> executeStep() async {
    this.expect(world.latestResultType, isNotNull);

    switch (world.latestResultType!) {
      case 'fetchMessageHistory':
        var result = world.latestResult as BatchHistoryResult;
        this.expect(result.more?.start, isNotNull);
        break;
      case 'fetchMessageAction':
        var result = world.latestResult as FetchMessageActionsResult;
        this.expect(result.moreActions?.start, isNotNull);
        break;
      default:
        this.expect(true, equals(false),
            reason:
                'Unexpected result type: ${world.latestResultType}: ${world.latestResult.runtimeType}\n${world.latestResult}');
        break;
    }
  }
}
