import 'package:meta/meta.dart';

import 'net/net.dart';
import 'parse.dart';
import 'crypto/crypto.dart';
import 'keyset.dart';

export 'net/net.dart';
export 'parse.dart';
export 'logging/logging.dart';
export 'crypto/crypto.dart';
export 'keyset.dart';
export 'endpoint.dart';
export 'uuid.dart';
export 'timetoken.dart';
export 'exceptions.dart';

class Core {
  /// Allows to have multiple [Keyset] associated with one instance of [PubNub].
  KeysetStore keysets = KeysetStore();

  NetworkModule networking;
  ParserModule parser;
  CryptoModule crypto;

  static String version = '1.4.4';

  Core(
      {Keyset defaultKeyset,
      @required this.networking,
      @required this.parser,
      this.crypto}) {
    if (defaultKeyset != null) {
      keysets.add(defaultKeyset, name: 'default', useAsDefault: true);
    }
  }
}
