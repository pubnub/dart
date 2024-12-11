import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepWhenFetchMessagesWithParams
    extends When3WithWorld<String,String, String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I fetch message history with {string} set to {string} for {string} channel');

  @override
  Future<void> executeStep(String includeCustomMessageType, String paramValue, String channel) async {
    try {
      var batchResult = await world.pubnub.batch
          .fetchMessages({channel}, includeCustomMessageType: bool.parse(paramValue));
      (world.latestResult as BatchHistoryResult).channels.keys.forEach((c) =>
          world.historyMessages.addAll(
              batchResult.channels[c] as Iterable<BatchHistoryResultEntry>));
      world.latestResult = batchResult;
      world.latestResultType = 'fetchMessages';
    } catch (e) {
      world.latestResultType = 'fetchMessagesWithMessageTypeTypeFailure';
      world.latestResult = e;
    }
  }
}
