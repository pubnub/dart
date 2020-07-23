import 'request.dart';

export 'request.dart' show Request, RequestHandler;
export 'request_type.dart' show RequestType, RequestTypeExtension;

abstract class NetworkModule {
  Future<RequestHandler> handle(Request request);

  Future<RequestHandler> handleCustomRequest(Request request);
}
