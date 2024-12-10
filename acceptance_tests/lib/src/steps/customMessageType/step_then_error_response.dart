import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../../world.dart';

class StepThenIReceivePublishErrorResponse extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I receive an error response');

  @override
  Future<void> executeStep() async {
    if(world.latestResultType == 'sendFile') {
      var result = world.latestResult as PublishFileMessageResult;
      this.expect(result.description?.toLowerCase(), contains('invalid_type'));
    } else {
       var result = world.latestResult as PublishException;
      this.expect(result.message.toLowerCase(), contains('invalid_type'));
    }
  }
}