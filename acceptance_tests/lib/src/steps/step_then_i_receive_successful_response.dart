import 'dart:io';

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
      case 'signal':
        var result = world.latestResult as SignalResult;
        this.expect(result.isError, equals(false),
            reason: 'Expected SignalResult.isError to be false');
        break;
      case 'time':
        var result = world.latestResult as Timetoken;
        this.expect(result.value, isA<BigInt>());
        break;
      case 'addPushChannels':
        var result = world.latestResult as AddPushChannelsResult;
        this.expect(result.status, equals(1));
        break;
      case 'removePushChannels':
        var result = world.latestResult as RemovePushChannelsResult;
        this.expect(result.status, equals(1));
        break;
      case 'listPushChannels':
        var result = world.latestResult as ListPushChannelsResult;
        this.expect(result.channels.length, greaterThan(0));
        break;
      case 'removeDevice':
        var result = world.latestResult as RemoveDeviceResult;
        this.expect(result.status, equals(1));
        break;
      case 'listFiles':
        var result = world.latestResult as ListFilesResult;
        this.expect(result.count, greaterThan(0));
        break;
      case 'publishFileMessage':
        var result = world.latestResult as PublishFileMessageResult;
        this.expect(result.isError, equals(false));
        break;
      case 'deleteFile':
        var result = world.latestResult as DeleteFileResult;
        this.expect(result, isNotNull);
        break;
      case 'downloadFile':
        var result = world.latestResult as DownloadFileResult;
        this.expect(result.fileContent, isA<List<int>>());
        break;
      case 'fetchMessageHistory':
        var result = world.latestResult as BatchHistoryResult;
        this.expect(result.channels.length, greaterThan(0));
        break;
      case 'fetchMessageHistoryWithActions':
        var result = world.latestResult as BatchHistoryResult;
        this.expect(
            result.channels.entries.first.value.first.actions?.entries.length ??
                0,
            greaterThan(0));
        break;
      case 'fetchMessageHistoryMulti':
        var result = world.latestResult as BatchHistoryResult;
        this.expect(result.channels.entries.length, greaterThan(1));
        break;
      case 'addMessageAction':
        var result = world.latestResult as AddMessageActionResult;
        this.expect(result.action.actionTimetoken, isNotNull);
        break;
      case 'fetchMessageAction':
        var result = world.latestResult as FetchMessageActionsResult;
        this.expect(result.actions.length, greaterThan(0));
        break;
      case 'deleteMessageAction':
        var result = world.latestResult as DeleteMessageActionResult;
        this.expect(result, isNotNull);
        break;
      default:
        this.expect(true, equals(false),
            reason:
                'Unexpected result type: ${world.latestResultType}: ${world.latestResult.runtimeType}\n${world.latestResult}');
        break;
    }
  }
}
