import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

import '../world.dart';

class StepWhenIListFiles extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I list files');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'listFiles';
      world.latestResult = await world.pubnub.files.listFiles('test');
    } catch (e) {
      world.latestResultType = 'listFilesFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIPublishFileMessage extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I publish file message');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'publishFileMessage';
      world.latestResult = await world.pubnub.files.publishFileMessage(
          'channel',
          FileMessage(FileInfo('id', 'name', 'url'), message: 'message'));
    } catch (e) {
      world.latestResultType = 'publishFileMessageFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIDeleteFile extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I delete file');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'deleteFile';
      world.latestResult =
          await world.pubnub.files.deleteFile('channel', 'fileId', 'fileName');
    } catch (e) {
      world.latestResultType = 'deleteFileFailure';
      world.latestResult = e;
    }
  }
}

class StepWhenIDownloadFile extends WhenWithWorld<PubNubWorld> {
  @override
  RegExp get pattern => RegExp(r'I download file');

  @override
  Future<void> executeStep() async {
    try {
      world.latestResultType = 'downloadFile';
      world.latestResult = await world.pubnub.files
          .downloadFile('channel', 'fileId', 'fileName');
    } catch (e) {
      world.latestResultType = 'downloadFileFailure';
      world.latestResult = e;
    }
  }
}
