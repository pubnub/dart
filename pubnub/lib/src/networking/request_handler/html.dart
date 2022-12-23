import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:form_data/form_data.dart';
import 'package:pool/pool.dart';
import 'package:pubnub/core.dart';

import '../response/response.dart';
import '../utils.dart';

final _logger = injectLogger('pubnub.networking.request_handler');

class RequestHandler extends IRequestHandler {
  final INetworkingModule _module;
  final int _id;
  final PoolResource _resource;

  HttpRequest request = HttpRequest();
  final _cancel = Completer<Exception>();

  Timer? _sendTimeoutTimer;
  Response? _response;
  bool _isReleased = false;
  void Function(dynamic)? _abortRequest;

  RequestHandler(this._module, this._id, this._resource);

  @override
  void cancel([reason]) {
    if (!isDone) {
      _logger.info(
          '($_id) Request has been cancelled (reason: ${reason.runtimeType}).');

      _cancel.complete(RequestCancelException(reason));

      if (_abortRequest != null) {
        _abortRequest!(RequestCancelException(reason));
      }
    }
  }

  @override
  bool get isCancelled => _cancel.isCompleted;

  bool get isDone => _cancel.isCompleted || _response != null;

  Future<Exception> get cancelReason => _cancel.future;

  @override
  Future<IResponse> response(Request data) async {
    _logger.info('($_id) Preparing request.');

    var headers = {...(data.headers ?? {})};
    var uri = prepareUri(_module.getOrigin(), data.uri ?? Uri());
    List<int>? body;

    if (data.type == RequestType.file) {
      var formData = FormData();

      for (var entry in (data.body as Map<String, dynamic>).entries) {
        if (entry.value is List<int>) {
          formData.addBytes(entry.key, entry.value);
        } else {
          formData.add(entry.key, entry.value);
        }
      }

      headers['Content-Type'] = formData.contentType;
      headers['Content-Length'] = formData.contentLength.toString();
      body = formData.body;
    } else {
      if (data.body != null) {
        headers['Content-Type'] = 'application/json';
        body = utf8.encode(data.body.toString());
      }
    }

    try {
      if (isCancelled) {
        throw await cancelReason;
      }

      request
        ..open(
          data.type.method,
          uri.replace(query: uri.query.replaceAll('+', '%20')).toString(),
        )
        ..responseType = 'arraybuffer';

      _abortRequest = (reason) {
        request.abort();
      };

      if (isCancelled) {
        throw await cancelReason;
      }

      _sendTimeoutTimer =
          Timer(Duration(milliseconds: data.type.sendTimeout), () {
        if (!isDone) {
          _cancel.complete(RequestTimeoutException());
          if (_abortRequest != null) {
            _abortRequest!(RequestTimeoutException());
          }
        }
      });

      for (var header in headers.entries) {
        // NOTE: See https://developer.mozilla.org/en-US/docs/Glossary/Forbidden_header_name
        if (!isHeaderForbidden(header.key)) {
          request.setRequestHeader(header.key, header.value);
        }
      }

      _logger.info('($_id) Starting request to "$uri"...');

      if (body != null) {
        request.send(Uint8List.fromList(body));
      } else {
        request.send();
      }

      var event = await Future.any([
        request.onLoad.first.then((_) => true),
        request.onError.first.then((_) => false)
      ]);

      if (!event) {
        throw Exception('XMLHttpRequest failed.');
      }

      var byteList = (request.response as ByteBuffer).asUint8List();

      var response = Response(byteList, request);
      _response = response;

      if (response.statusCode < 200 || response.statusCode > 299) {
        throw RequestFailureException(response);
      }

      _logger.info('($_id) Request succeed!');

      _logger.info('${response.statusCode} ${response.text}');

      return response;
    } on RequestCancelException {
      rethrow;
    } on RequestFailureException {
      rethrow;
    } on RequestTimeoutException {
      rethrow;
    } catch (e) {
      _logger.fatal('($_id) Request failed (${e.runtimeType}) ($e)');
      throw RequestOtherException(e);
    } finally {
      if (!_isReleased) {
        _isReleased = true;
        _resource.release();
        request.abort();
        _sendTimeoutTimer?.cancel();
        _logger.info('($_id) Resource released...');
      }
    }
  }
}
