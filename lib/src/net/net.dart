import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:pool/pool.dart';

import 'package:pubnub/src/core/net/net.dart';
import 'package:pubnub/src/core/net/request.dart';
import 'package:pubnub/src/net/exceptions.dart';

final _log = Logger('pubnub.networking');

class PubNubRequestHandler extends RequestHandler {
  Request request;
  Dio _client;

  final CancelToken _cancelToken = CancelToken();
  final Completer<Response> _contents = Completer();
  PoolResource _resource;

  PubNubRequestHandler(this.request, Dio client, PoolResource resource) {
    _client = client;
    _resource = resource;
    _initialize();
  }

  void _initialize() async {
    var uri = Uri(
        pathSegments: request.pathSegments,
        queryParameters: request.queryParameters);
    _log.info('Starting request to ${uri}...');
    try {
      var response = await _client.requestUri<String>(uri,
          data: request.body,
          options: Options(
            method: request.type.method,
            headers: request.headers,
          ),
          cancelToken: _cancelToken);

      _log.info('Request succeed! (${response.request.uri})');
      _contents.complete(response);
    } on DioError catch (e) {
      _log.info('Request failed ($e, ${e.message})');
      switch (e.type) {
        case DioErrorType.CANCEL:
          _contents.completeError(PubNubRequestCancelException(e.error));
          break;
        case DioErrorType.CONNECT_TIMEOUT:
        case DioErrorType.RECEIVE_TIMEOUT:
        case DioErrorType.SEND_TIMEOUT:
          _contents.completeError(PubNubRequestTimeoutException());
          break;
        case DioErrorType.RESPONSE:
          _contents
              .completeError(PubNubRequestFailureException(e.response.data));
          break;
        case DioErrorType.DEFAULT:
        default:
          _contents.completeError(PubNubRequestOtherException());
          break;
      }
    } finally {
      _resource.release();
    }
  }

  @override
  Future<String> text() async {
    return (await _contents.future).data;
  }

  @override
  Future<Map<String, List<String>>> headers() async {
    return (await _contents.future).headers.map;
  }

  @override
  bool get isCancelled => _cancelToken.isCancelled;

  @override
  void cancel([dynamic reason]) {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel(reason);
    }
  }
}

class PubNubNetworkingModule implements NetworkingModule {
  static final Uri origin = Uri(scheme: 'https', host: 'ps.pndsn.com');

  final Pool _pool = Pool(10);
  final Dio _client = Dio(BaseOptions(baseUrl: '${origin.toString()}/'));

  @override
  Future<RequestHandler> handle(Request request) async {
    var resource = await _pool.request();
    return PubNubRequestHandler(request, _client, resource);
  }
}
