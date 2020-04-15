import 'request.dart';

export 'request.dart' show Request, RequestHandler;
export 'request_type.dart' show RequestType, RequestTypeExtension;

abstract class NetworkingModule {
  Future<RequestHandler> handle(Request request);
}
