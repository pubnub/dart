import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:form_data/form_data.dart';
import 'package:pool/pool.dart';
import 'package:pubnub/core.dart';

import '../response/response.dart';

final _logger = injectLogger('pubnub.networking.request_handler');

class RequestHandler extends IRequestHandler {
  final INetworkingModule _module;
  final int _id;
  final PoolResource _resource;

  HttpClient client = HttpClient();
  final _cancel = Completer<Exception>();

  Timer _sendTimeoutTimer;
  Response _response;
  bool _isReleased = false;
  void Function(dynamic) _abortRequest;

  RequestHandler(this._module, this._id, this._resource);

  @override
  void cancel([reason]) {
    if (!isDone) {
      _logger.info(
          '($_id) Request has been cancelled (reason: ${reason.runtimeType}).');

      _cancel.complete(PubNubRequestCancelException(reason));

      if (_abortRequest != null) {
        _abortRequest(PubNubRequestCancelException(reason));
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
    var uri = prepareUri(_module.getOrigin(), data.uri);
    List<int> body;

    if (data.type == RequestType.file) {
      var formData = FormData();

      for (var entry in (data.body as Map<String, dynamic>).entries) {
        if (entry.value is List<int>) {
          formData.addFile(entry.key, entry.value);
        } else {
          formData.add(entry.key, entry.value);
        }
      }

      headers['Content-Type'] = formData.contentType;
      headers['Content-Length'] = formData.contentLength.toString();
      body = formData.body;
    } else {
      if (data.body != null) {
        body = utf8.encode(data.body.toString());
      }
    }

    _logger.info('($_id) Starting request to "${uri}"...');

    try {
      if (isCancelled) {
        throw await cancelReason;
      }

      var request = await client.openUrl(
        data.type.method,
        Uri.parse(uri.toString().replaceAll('+', '%20')),
      );

      _abortRequest = (reason) {
        request.abort(reason);
      };

      if (isCancelled) {
        throw await cancelReason;
      }

      _sendTimeoutTimer =
          Timer(Duration(milliseconds: data.type.sendTimeout), () {
        if (!isDone) {
          _cancel.complete(PubNubRequestTimeoutException());
          _abortRequest(PubNubRequestTimeoutException());
        }
      });

      if (body != null) {
        request.add(body);
      }

      for (var header in headers.entries) {
        request.headers.set(header.key, header.value);
      }

      var clientResponse = await request.close();

      var byteList =
          await clientResponse.fold<List<int>>(<int>[], (a, b) => [...a, ...b]);

      _response = Response(byteList, clientResponse);

      if (_response.statusCode < 200 || _response.statusCode > 299) {
        throw PubNubRequestFailureException(_response);
      }

      _logger.info('(${_id}) Request succeed!');

      return _response;
    } on PubNubRequestCancelException {
      rethrow;
    } on PubNubRequestFailureException {
      rethrow;
    } on PubNubRequestTimeoutException {
      rethrow;
    } catch (e) {
      _logger.fatal('($_id) Request failed (${e.runtimeType}) (${e})');
      throw PubNubRequestOtherException(e);
    } finally {
      if (!_isReleased) {
        _isReleased = true;
        _resource?.release();
        client.close(force: true);
        _sendTimeoutTimer?.cancel();
        _logger.info('($_id) Resource released...');
      }
    }
  }
}
