import 'package:meta/meta.dart';

import 'net/net.dart';
import 'parser.dart';
import 'crypto/crypto.dart';
import 'supervisor/supervisor.dart';
import 'keyset.dart';

export 'net/net.dart';
export 'parser.dart';
export 'logging/logging.dart';
export 'crypto/crypto.dart';
export 'supervisor/supervisor.dart';
export 'keyset.dart';
export 'endpoint.dart';
export 'uuid.dart';
export 'timetoken.dart';
export 'exceptions.dart';

class Core {
  /// Allows to have multiple [Keyset] associated with one instance of [PubNub].
  KeysetStore keysets = KeysetStore();

  INetworkingModule networking;
  IParserModule parser;
  ICryptoModule crypto;
  SupervisorModule supervisor = SupervisorModule();

  static String version = '2.0.1';

  Core(
      {Keyset defaultKeyset,
      @required this.networking,
      @required this.parser,
      @required this.crypto}) {
    if (defaultKeyset != null) {
      keysets.add(defaultKeyset, name: 'default', useAsDefault: true);
    }

    networking.register(this);
    parser.register(this);
    crypto.register(this);
  }
}
