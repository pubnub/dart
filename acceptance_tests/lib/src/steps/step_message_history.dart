import 'package:gherkin/gherkin.dart';

import '../world.dart';

class StepWhenIFetchMessageHistoryForSingleChannel
    extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I fetch message history for single channel');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'fetchMessageHistory';
      world.latestResult = await world.pubnub.batch.fetchMessages({'channel'});
    } catch (e) {
      world.latestResultType = 'fetchMessageHistoryFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIFetchMessageHistoryForMultipleChannels
    extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I fetch message history for multiple channels');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'fetchMessageHistoryMulti';
      world.latestResult =
          await world.pubnub.batch.fetchMessages({'channel1', 'channel2'});
    } catch (e) {
      world.latestResultType = 'fetchMessageHistoryMultiFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIFetchMessageHistoryWithMessageActions
    extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I fetch message history with message actions');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'fetchMessageHistoryWithActions';
      world.latestResult = await world.pubnub.batch
          .fetchMessages({'channel1'}, includeMessageActions: true);
    } catch (e) {
      world.latestResultType = 'fetchMessageHistoryWithActionsFailure';
      world.latestResult = e;
    }
  }
}
