import 'package:meta/meta.dart';

import 'net/net.dart';
import 'parse.dart';
import 'keyset.dart';

export 'net/net.dart';
export 'parse.dart';
export 'logging/logging.dart';
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

  static String version = '1.1.3';

  Core(
      {Keyset defaultKeyset,
      @required this.networking,
      @required this.parser}) {
    if (defaultKeyset != null) {
      keysets.add(defaultKeyset, name: 'default', useAsDefault: true);
    }
  }
}
