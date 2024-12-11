import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepWhenFetchMessagesWithCustomMessageType
    extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'When I fetch message history with customMessageType for {string} channel');

  @override
  Future<void> executeStep(String channel) async {
    try {
      var batchResult = await world.pubnub.batch
          .fetchMessages({channel}, includeMessageType: true, includeCustomMessageType: true);
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
