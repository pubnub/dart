import 'package:logging/logging.dart';

import 'net/net.dart';
import 'parse.dart';
import 'keyset.dart';

export 'keyset.dart';
export 'net/net.dart';
export 'endpoint.dart';
export 'uuid.dart';
export 'timetoken.dart';
export 'exceptions.dart';
export 'package:logging/logging.dart' show Level;

class Core {
  /// Allows to have multiple [Keyset] associated with one instance of [PubNub].
  KeysetStore keysets = KeysetStore();

  NetworkingModule networking;
  ParserModule parser;
  Logger log;

  static String version = '1.0.5';

  Core({Keyset defaultKeyset, this.networking, this.parser}) {
    if (defaultKeyset != null) {
      keysets.add(defaultKeyset, name: 'default', useAsDefault: true);
    }

    hierarchicalLoggingEnabled = true;
    log = Logger('pubnub');

    log.level = Level.SEVERE;
    log.onRecord.listen((record) {
      print('(${record.time}) <${record.loggerName}> ${record.message}');
    });
  }
}
