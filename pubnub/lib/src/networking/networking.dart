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
  RetryPolicy? retryPolicy = RetryPolicy.exponential();

  /// Origin used for all requests.
  ///
  /// If `null`, then defaults to the PubNub default origin.
  final String? origin;

  /// Whether `https` or `http` should be used.
  final bool ssl;

  /// Whether to negotiate HTTP/2 (with automatic HTTP/1.1 fallback) on the
  /// native (`dart:io`) transport.
  ///
  /// Defaults to `true`. When `true`, requests use HTTP/2 if the origin
  /// negotiates `h2` via TLS ALPN, otherwise they transparently fall back to
  /// HTTP/1.1. Set to `false` to always use HTTP/1.1 (e.g. behind a proxy that
  /// is not detected from the environment). Has no effect on the web platform,
  /// where the browser controls the protocol.
  final bool enableHttp2;

  NetworkingModule(
      {RetryPolicy? retryPolicy, this.origin, bool? ssl, bool? enableHttp2})
      : ssl = ssl ?? true,
        enableHttp2 = enableHttp2 ?? true {
    this.retryPolicy = retryPolicy ?? RetryPolicy.exponential();
  }

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

  /// Releases any transport resources held by this module.
  ///
  /// On the native platform this closes pooled HTTP/2 connections and their
  /// keep-alive timers. Optional to call — idle connections are otherwise
  /// reaped automatically — but useful for a deterministic shutdown. No-op on
  /// the web platform.
  void dispose() {
    disposeTransport(this);
  }

  @override
  String toString() {
    var policyString = retryPolicy?.toString() ?? 'none';
    return 'NetworkingModule(origin: $origin, ssl: $ssl, retryPolicy: $policyString)';
  }
}
