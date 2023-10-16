import 'package:acceptance_tests/src/steps/crypto_module/step_given_cipher_key.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_given_legacy_crypto.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_given_multiple_cryptors.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_given_vector.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_then_decrypt_success.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_then_decrypted.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_then_outcome.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_when_decrypt.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_when_decrypt_as.dart';
import 'package:acceptance_tests/src/steps/crypto_module/step_when_encrypt.dart';

import '../../world.dart';

import 'package:gherkin/gherkin.dart';

import 'step_given_crypto_module.dart';

final List<StepDefinitionGeneric<PubNubWorld>> cryptoSteps = [
  StepGivenCryptoModule(),
  StepGivenCipherKey(),
  StepGivenVector(),
  StepWhenDecryptFileAs(),
  StepThenDecryptedContentEquals(),
  StepGivenLegacyCryptoModule(),
  StepWhenDecryptFile(),
  StepThenOutcome(),
  StepWhenEncrypt(),
  ThenDecryptSuccessWithLegacy(),
  StepGivenCryptoModuleWithMultipleCryptors()
];
