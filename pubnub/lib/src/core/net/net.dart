import '../core.dart';
import 'request_handler.dart';

export 'request.dart';
export 'request_type.dart';
export 'request_handler.dart';
export 'response.dart';
export 'exceptions.dart';

abstract class INetworkingModule {
  void register(Core core);

  Uri getOrigin();

  Future<IRequestHandler> handler();
}
