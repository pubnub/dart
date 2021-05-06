import 'package:pool/pool.dart';
import 'package:pubnub/core.dart';

import 'meta/meta.dart';
import 'request_handler/request_handler.dart';

class NetworkingModule extends INetworkingModule {
  static int _requestCounter = 0;

  final Pool _pool = Pool(10);

  /// Retry policy.
  ///
  /// If retry policy is null, then retries are not attempted.
  final RetryPolicy? retryPolicy;

  /// Origin used for all requests.
  ///
  /// If `null`, then defaults to the PubNub default origin.
  final String? origin;

  /// Whether `https` or `http` should be used.
  final bool ssl;

  NetworkingModule({this.retryPolicy, this.origin, this.ssl = true});

  @override
  Uri getOrigin() {
    var originUri = origin != null
        ? (ssl ? Uri.https(origin!, '') : Uri.http(origin!, ''))
        : null;

    return Uri(
      scheme: originUri?.scheme == '' ? 'https' : originUri?.scheme ?? 'https',
      host: originUri?.host ?? 'ps.pndsn.com',
      port: originUri?.port,
      queryParameters: {'pnsdk': 'PubNub-Dart/${Core.version}'},
    );
  }

  @override
  Future<IRequestHandler> handler() async {
    var requestId = _requestCounter++;
    var resource = await _pool.request();

    return RequestHandler(this, requestId, resource);
  }

  @override
  void register(Core core) {
    core.supervisor.registerDiagnostic(getNetworkDiagnostic);
    core.supervisor
        .registerStrategy(NetworkingStrategy(retryPolicy: retryPolicy));
  }
}
