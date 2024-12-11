import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../../world.dart';

class StepWhenFetchMessagesWithMessageType
    extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I fetch message history with messageType for {string} channel');

  @override
  Future<void> executeStep(String channel) async {
    try {
      var batchResult = await world.pubnub.batch.fetchMessages({channel},
          includeMessageType: true);
      (world.latestResult as BatchHistoryResult).channels.keys.forEach( (c) => 
        world.historyMessages.addAll(batchResult.channels[c] as Iterable<BatchHistoryResultEntry>)
      );   
      world.latestResult = batchResult;
      world.latestResultType = 'fetchMessages';
    } catch (e) {
      world.latestResultType = 'fetchMessagesWithMessageTypeTypeFailure';
      world.latestResult = e;
    }
  }
}
