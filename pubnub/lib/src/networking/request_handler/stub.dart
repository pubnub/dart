import 'package:pool/pool.dart';
import 'package:pubnub/core.dart';

class RequestHandler extends IRequestHandler {
  RequestHandler(
      INetworkingModule module, int requestId, PoolResource resource);

  @override
  void cancel([reason]) {}

  @override
  Future<IResponse> response(Request request) {
    throw UnimplementedError();
  }

  @override
  bool get isCancelled => throw UnimplementedError();
}
