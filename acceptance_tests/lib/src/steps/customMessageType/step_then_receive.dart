import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepThenIReceiveMessagesInSubscriptionResponse
    extends Then1WithWorld<int, PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I receive {int} messages in my subscribe response');

  @override
  Future<void> executeStep(int count) async {
    expect(world.messages.length, 2);
  }
}
