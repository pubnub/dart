import 'dart:async';
import 'package:dio/dio.dart';
import 'package:pool/pool.dart';

import 'package:pubnub/core.dart';
import 'meta/meta.dart';
import 'request_handler.dart';

/// Default module used for networking in PubNub SDK.
class NetworkingModule implements INetworkingModule {
  static int _requestCounter = 0;

  /// Retry policy.
  ///
  /// If retry policy is null, then no retries are attempted.
  final RetryPolicy retryPolicy;
  final Pool _pool = Pool(10);
  final Dio _client = Dio();

  /// You can pass in your own [RetryPolicy].
  NetworkingModule({this.retryPolicy});

  /// @nodoc
  @override
  Future<RequestHandler> handler() async {
    var requestId = _requestCounter++;

    return RequestHandler(requestId,
        client: _client, resource: _pool.request());
  }

  /// @nodoc
  @override
  void register(Core core) {
    core.supervisor.registerDiagnostic(getNetworkDiagnostic);
    core.supervisor
        .registerStrategy(NetworkingStrategy(retryPolicy: retryPolicy));
  }
}
