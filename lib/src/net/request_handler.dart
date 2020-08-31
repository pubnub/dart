import 'package:dio/dio.dart' as dio;
import 'package:pool/pool.dart' show PoolResource;
import 'package:pubnub/pubnub.dart';

import 'response.dart';

final _logger = injectLogger('pubnub.networking.request_handler');

class RequestHandler extends IRequestHandler {
  final int _id;
  final dio.Dio _client;
  final Future<PoolResource> _resourceP;
  PoolResource _resource;
  final dio.CancelToken _cancelToken = dio.CancelToken();

  bool _isReleased = false;

  RequestHandler(this._id, {dio.Dio client, Future<PoolResource> resource})
      : _client = client,
        _resourceP = resource;

  @override
  Future<IResponse> response(Request request) async {
    _logger.info('($_id) Awaiting for resource...');
    _resource = await _resourceP;
    _logger.info('($_id) Resource obtained.');

    var uri = prepareUri(request.uri);
    var body = request.body;

    _logger.info('($_id) Starting request to ${uri}...');

    if (request.type == RequestType.file) {
      body =
          dio.FormData.fromMap((body as Map<String, dynamic>).map((key, value) {
        if (value is List<int>) {
          return MapEntry(key, dio.MultipartFile.fromBytes(value));
        } else {
          return MapEntry(key, value);
        }
      }));
    }

    try {
      var response = await _client.requestUri<List<int>>(
        uri,
        data: body,
        options: dio.RequestOptions(
          method: request.type.method,
          headers: request.headers,
          responseType: dio.ResponseType.bytes,
          receiveTimeout: request.type.receiveTimeout,
          sendTimeout: request.type.sendTimeout,
        ),
        cancelToken: _cancelToken,
      );

      _logger.info('(${_id}) Request succeed!');

      return Response(response);
    } on dio.DioError catch (e) {
      _logger.info('($_id) Request failed ($e, ${e.message})');
      switch (e.type) {
        case dio.DioErrorType.CANCEL:
          throw PubNubRequestCancelException(e.error);
          break;
        case dio.DioErrorType.CONNECT_TIMEOUT:
        case dio.DioErrorType.RECEIVE_TIMEOUT:
        case dio.DioErrorType.SEND_TIMEOUT:
          throw PubNubRequestTimeoutException(e);
          break;
        case dio.DioErrorType.RESPONSE:
          var response = dio.Response<List<int>>(
              data: e.response.data,
              headers: e.response.headers,
              statusCode: e.response.statusCode);

          throw PubNubRequestFailureException(Response(response));
          break;
        case dio.DioErrorType.DEFAULT:
        default:
          throw PubNubRequestOtherException(e.error);
          break;
      }
    } catch (e) {
      _logger.fatal('($_id) Request failed ($e)');
      throw PubNubRequestOtherException(e);
    } finally {
      if (!_isReleased) {
        _isReleased = true;
        _resource?.release();
        _logger.info('($_id) Resource released...');
      }
    }
  }

  @override
  bool get isCancelled => _cancelToken.isCancelled;

  @override
  void cancel([dynamic reason]) {
    if (!_cancelToken.isCancelled && !_isReleased) {
      _cancelToken.cancel(reason);
      _resource?.release();
      _logger.info('($_id) Request cancelled and resource released.');
    }
  }
}
