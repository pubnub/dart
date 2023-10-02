import 'dart:io';

import 'package:gherkin/gherkin.dart';
import 'package:test/test.dart';

import '../../world.dart';
import '_utils.dart';

class StepThenDecryptedContentEquals
    extends Then1WithWorld<String, PubNubWorld> {
  @override
  RegExp get pattern =>
      RegExp(r'Decrypted file content equal to the {string} file content');

  @override
  Future<void> executeStep(String file) async {
    var sourceContent =
        File(getCryptoFilePath(file)).readAsBytesSync().toList();
    var ec = world.scenarioContext['decryptedContent'];
    this.expect(listEquals(ec, sourceContent), isTrue);
  }
}
