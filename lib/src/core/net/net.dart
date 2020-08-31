import '../core.dart';
import 'request_handler.dart';

export 'request.dart' show Request;
export 'request_type.dart' show RequestType, RequestTypeExtension;
export 'request_handler.dart' show IRequestHandler;
export 'response.dart' show IResponse;
export 'exceptions.dart'
    show
        PubNubRequestCancelException,
        PubNubRequestFailureException,
        PubNubRequestOtherException,
        PubNubRequestTimeoutException;

abstract class INetworkingModule {
  void register(Core core);

  Future<IRequestHandler> handler();
}
