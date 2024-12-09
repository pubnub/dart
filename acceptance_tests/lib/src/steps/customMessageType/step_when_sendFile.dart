import 'package:gherkin/gherkin.dart';

import '../../world.dart';

class StepWhenISendFileCustomType
    extends When1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'I send a file with {string} customMessageType');

  @override
  Future<void> executeStep(String customMesageType) async {
    try {
      world.latestResult = await world.pubnub.files.sendFile('test', 'helloFile.txt', [12,16], customMessageType: customMesageType);
      world.latestResultType = 'sendFile';
    } catch (e) {
      world.latestResultType = 'sendFileFailure';
      world.latestResult = e;
    }
  }
}
