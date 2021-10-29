import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

class KeysetParameter extends CustomParameter<Keyset> {
  KeysetParameter()
      : super(
            'keyset',
            RegExp(r'(demo|invalid|crypto|invalid-crypto)',
                caseSensitive: false), (c) {
          switch (c.toLowerCase()) {
            case 'demo':
              return Keyset(
                subscribeKey: 'demo',
                publishKey: 'demo',
                uuid: UUID('dart-acceptance-testing'),
              );
            case 'invalid':
              return Keyset(
                subscribeKey: 'invalid',
                publishKey: 'invalid',
                uuid: UUID('dart-acceptance-testing'),
              );
            case 'crypto':
              return Keyset(
                subscribeKey: 'demo',
                publishKey: 'demo',
                uuid: UUID('dart-acceptance-testing'),
                cipherKey: CipherKey.fromUtf8('enigma'),
              );
            case 'invalid-crypto':
              return Keyset(
                subscribeKey: 'demo',
                publishKey: 'demo',
                uuid: UUID('dart-acceptance-testing'),
                cipherKey: CipherKey.fromUtf8('invalid'),
              );
          }
        });
}
