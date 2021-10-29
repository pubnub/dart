import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '../world.dart';

class StepThenIReceiveErrorResponse extends ThenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I receive error response');

  @override
  Future<void> executeStep() async {
    this.expect(world.latestResultType, isNotNull);

    switch (world.latestResultType!) {
      case 'publishFileMessage':
        var result = world.latestResult as PublishFileMessageResult;
        this.expect(result.isError, equals(true));
        break;
      case 'publishFailure':
        var result = world.latestResult as PublishException;
        this.expect(result.message, equals('Invalid subscribe key'));
        break;
      case 'listPushChannelsFailureWithoutTopic':
      case 'addPushChannelsFailureWithoutTopic':
      case 'removePushChannelsFailureWithoutTopic':
      case 'removeDeviceFailureWithoutTopic':
        var result = world.latestResult as InvariantException;
        this.expect(result.message, equals('topic cannot be null'));
        break;
      case 'addMessageActionFailure':
        var result = world.latestResult as PubNubException;
        this.expect(
            result.message,
            equals(
                '403 error: Supplied authorization key does not have the permissions required to perform this operation.'));
        break;
      case 'deleteMessageActionFailure':
        var result = world.latestResult as PubNubException;
        this.expect(
            result.message,
            equals(
                '403 error: Supplied authorization key does not have the permissions required to perform this operation.'));
        break;
      default:
        this.expect(true, equals(false),
            reason:
                'Unexpected result type: ${world.latestResultType}: ${world.latestResult.runtimeType}\n${world.latestResult}');
        break;
    }
  }
}
