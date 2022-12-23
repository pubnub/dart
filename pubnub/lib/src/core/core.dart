import 'net/net.dart';
import 'parser.dart';
import 'crypto/crypto.dart';
import 'supervisor/supervisor.dart';
import 'keyset/store.dart';
import 'keyset/keyset.dart';

class Core {
  /// Allows to have multiple [Keyset] associated with one instance.
  KeysetStore keysets = KeysetStore();

  /// Internal module responsible for networking.
  INetworkingModule networking;

  /// Internal module responsible for parsing.
  IParserModule parser;

  /// Internal module responsible for cryptography.
  ICryptoModule crypto;

  /// Internal module responsible for supervising.
  SupervisorModule supervisor = SupervisorModule();

  static String version = '4.2.2';

  Core(
      {Keyset? defaultKeyset,
      required this.networking,
      required this.parser,
      required this.crypto}) {
    if (defaultKeyset != null) {
      keysets.add('default', defaultKeyset, useAsDefault: true);
    }

    networking.register(this);
    parser.register(this);
    crypto.register(this);
  }
}
