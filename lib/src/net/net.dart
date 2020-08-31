import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pool/pool.dart';
import 'package:pubnub/pubnub.dart';

import 'meta/meta.dart';
import 'request_handler.dart';

class NetworkingModule implements INetworkingModule {
  static int _requestCounter = 0;

  final RetryPolicy retryPolicy;
  final Pool _pool = Pool(10);
  final Dio _client = Dio();

  NetworkingModule({this.retryPolicy});

  @override
  Future<RequestHandler> handler() async {
    var requestId = _requestCounter++;

    return RequestHandler(requestId,
        client: _client, resource: _pool.request());
  }

  @override
  void register(Core core) {
    core.supervisor.registerDiagnostic(getNetworkDiagnostic);
    core.supervisor
        .registerStrategy(NetworkingStrategy(retryPolicy: retryPolicy));
  }
}
