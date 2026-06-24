import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:form_data/form_data.dart';
import 'package:http2/transport.dart';
import 'package:pool/pool.dart';
import 'package:pubnub/core.dart';

import '../networking.dart';
import '../response/io.dart';
import 'io_connection_manager.dart';

final _logger = injectLogger('pubnub.networking.request_handler');

/// Maximum number of redirects followed on the HTTP/2 path, mirroring the
/// default behaviour of `dart:io`'s [HttpClient].
const _maxRedirects = 5;

/// Releases any HTTP/2 connections (and their timers) held for [module].
///
/// Invoked by `NetworkingModule.dispose()`. No-op on platforms without an
/// HTTP/2 transport.
void disposeTransport(INetworkingModule module) => disposeHttp2Manager(module);

class RequestHandler extends IRequestHandler {
  final INetworkingModule _module;
  final int _id;
  final PoolResource _resource;

  HttpClient _client = HttpClient();

  /// Whether a custom [HttpClient] was injected (e.g. for testing). When set,
  /// requests always use the HTTP/1.1 path so the injected client is honoured.
  bool _clientInjected = false;

  HttpClient get client => _client;
  set client(HttpClient value) {
    _client = value;
    _clientInjected = true;
  }

  final _cancel = Completer<Exception>();

  Timer? _sendTimeoutTimer;
  Response? _response;
  bool _isReleased = false;
  void Function(dynamic)? _abortRequest;

  RequestHandler(this._module, this._id, this._resource);

  @override
  void cancel([reason]) {
    if (!isDone) {
      _logger.fine(
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

  bool get _enableHttp2 => _module is NetworkingModule
      ? (_module as NetworkingModule).enableHttp2
      : true;

  /// Decides whether the HTTP/2 path should be attempted for [uri].
  ///
  /// HTTP/2 requires TLS (ALPN), the feature must be enabled, no custom client
  /// can be in use, and no HTTP proxy may be configured (the raw-socket path
  /// cannot route through `HttpClient`'s proxy support).
  bool _shouldUseHttp2(Uri uri) {
    if (_clientInjected) return false;
    if (uri.scheme != 'https') return false;
    if (!_enableHttp2) return false;
    try {
      if (HttpClient.findProxyFromEnvironment(uri) != 'DIRECT') return false;
    } catch (_) {
      // If proxy resolution fails, prefer HTTP/1.1 to be safe.
      return false;
    }
    return true;
  }

  @override
  Future<IResponse> response(Request data) async {
    try {
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
          if (data.headers != null && data.headers!.isNotEmpty) {
            data.headers!.forEach((k, v) => headers[k] = v);
          }
          body = utf8.encode(data.body.toString());
        }
      }

      if (isCancelled) {
        throw await cancelReason;
      }

      var requestUri = uri.replace(query: uri.query.replaceAll('+', '%20'));

      _logger.fine(LogEvent(
          message: 'Sending HTTP Request',
          details: data,
          detailsType: LogEventDetailsType.networkRequestInfo));

      var response = _shouldUseHttp2(requestUri)
          ? await _responseViaHttp2(data, requestUri, headers, body)
          : await _responseViaHttp1(data, requestUri, headers, body);

      _logger.fine(LogEvent(
          message: 'Received HTTP response:',
          details: {'request': data, 'response': response},
          detailsType: LogEventDetailsType.networkResponseInfo));
      _response = response;

      if (response.statusCode < 200 || response.statusCode > 299) {
        throw RequestFailureException(response,
            statusCode: response.statusCode);
      }

      return response;
    } on RequestCancelException {
      rethrow;
    } on RequestFailureException {
      rethrow;
    } on RequestTimeoutException {
      rethrow;
    } on RequestOtherException {
      rethrow;
    } catch (e) {
      _logger.fine('Request failed (${e.runtimeType}) ($e)');
      throw RequestOtherException(e);
    } finally {
      if (!_isReleased) {
        _isReleased = true;
        _resource.release();
        _client.close(force: true);
        _sendTimeoutTimer?.cancel();
        _logger.fine('Networking resource released.');
      }
    }
  }

  /// Executes the request over HTTP/1.1 using `dart:io`'s [HttpClient].
  Future<Response> _responseViaHttp1(Request data, Uri requestUri,
      Map<String, String> headers, List<int>? body) async {
    var request = await _client.openUrl(data.type.method, requestUri);

    _abortRequest = (reason) {
      request.abort(reason);
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
      request.headers.set(header.key, header.value);
    }

    if (body != null) {
      request.add(body);
    }

    var clientResponse = await request.close();

    var builder = BytesBuilder(copy: false);
    await clientResponse.forEach(builder.add);

    return Response.fromHttpClientResponse(builder.takeBytes(), clientResponse);
  }

  /// Executes the request over HTTP/2 (multiplexed), falling back to HTTP/1.1
  /// if the origin does not negotiate `h2` via ALPN.
  ///
  /// 3xx redirects are followed manually for GET/HEAD to preserve the effective
  /// behaviour of the HTTP/1.1 path (where [HttpClient] auto-follows redirects).
  Future<Response> _responseViaHttp2(Request data, Uri requestUri,
      Map<String, String> headers, List<int>? body) async {
    var manager = http2ManagerFor(_module);

    var currentUri = requestUri;
    var currentBody = body;
    var currentHeaders = headers;

    _sendTimeoutTimer =
        Timer(Duration(milliseconds: data.type.sendTimeout), () {
      if (!isDone) {
        _cancel.complete(RequestTimeoutException());
        if (_abortRequest != null) {
          _abortRequest!(RequestTimeoutException());
        }
      }
    });

    for (var redirects = 0;; redirects++) {
      if (isCancelled) {
        throw await cancelReason;
      }

      // Always derive content-length from the actual body so it can never
      // disagree with what is sent (e.g. on a redirect that drops the body).
      var h2Headers = {...currentHeaders}
        ..removeWhere((k, v) => k.toLowerCase() == 'content-length');
      if (currentBody != null) {
        h2Headers['content-length'] = currentBody.length.toString();
      }
      // Match dart:io HttpClient, which requests gzip and transparently
      // decompresses it (see _consumeHttp2Stream).
      if (!h2Headers.keys.any((k) => k.toLowerCase() == 'accept-encoding')) {
        h2Headers['accept-encoding'] = 'gzip';
      }

      Http2Stream? h2;
      try {
        h2 = await manager.openStream(
          currentUri,
          isSubscribe: data.type == RequestType.subscribe,
          connectTimeout: Duration(milliseconds: data.type.connectTimeout),
          headers: buildHttp2Headers(
              method: data.type.method, uri: currentUri, headers: h2Headers),
          endStream: currentBody == null,
        );
      } on TimeoutException {
        // The TLS/ALPN connection could not be established in time. Surface it
        // as a request timeout so the network diagnostics treat it as retryable.
        throw RequestTimeoutException();
      }

      // Origin does not support HTTP/2 — fall back to HTTP/1.1 for this request.
      if (h2 == null) {
        return _responseViaHttp1(data, currentUri, currentHeaders, currentBody);
      }

      // Cancellation/timeout may have fired while the stream was opening; tear
      // down the freshly-opened stream and surface the reason.
      if (isCancelled) {
        try {
          h2.stream.terminate();
        } catch (_) {}
        h2.done();
        throw await cancelReason;
      }

      Response response;
      try {
        response = await _consumeHttp2Stream(h2.stream, currentBody);
      } finally {
        h2.done();
      }

      var location = response.headers['location'];
      if (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          (data.type.method == 'GET' || data.type.method == 'HEAD') &&
          redirects < _maxRedirects &&
          location != null &&
          location.isNotEmpty) {
        currentUri = currentUri.resolve(location.first);
        // The redirected request carries no body, so drop body-specific headers.
        currentBody = null;
        currentHeaders = {...currentHeaders}..removeWhere((k, v) {
            var lower = k.toLowerCase();
            return lower == 'content-length' || lower == 'content-type';
          });
        continue;
      }

      return response;
    }
  }

  /// Sends the request body (if any) and assembles the response from an HTTP/2
  /// stream's incoming messages.
  Future<Response> _consumeHttp2Stream(
      ClientTransportStream stream, List<int>? body) async {
    var completer = Completer<Response>();
    var bytes = <int>[];
    int? statusCode;
    var responseHeaders = <String, List<String>>{};
    var headersSeen = false;
    StreamSubscription<StreamMessage>? subscription;

    _abortRequest = (reason) {
      try {
        stream.terminate();
      } catch (_) {}
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
            reason is Exception ? reason : RequestOtherException(reason));
      }
    };

    subscription = stream.incomingMessages.listen(
      (message) {
        if (message is HeadersStreamMessage) {
          // Only the first HEADERS frame carries the response status/headers;
          // any subsequent HEADERS frame is a trailers block and is ignored.
          if (headersSeen) return;
          headersSeen = true;
          for (var header in message.headers) {
            var name = String.fromCharCodes(header.name);
            var value = String.fromCharCodes(header.value);
            if (name == ':status') {
              statusCode = int.tryParse(value);
            } else if (!name.startsWith(':')) {
              responseHeaders.putIfAbsent(name, () => <String>[]).add(value);
            }
          }
        } else if (message is DataStreamMessage) {
          bytes.addAll(message.bytes);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          // Surface transport-level failures as HttpException so the existing
          // network diagnostics recognise them (and subscribe retries fire).
          // The outer handler wraps this in RequestOtherException once.
          completer.completeError((e is HttpException || e is SocketException)
              ? e
              : HttpException('HTTP/2 transport error: $e'));
        }
      },
      onDone: () {
        if (completer.isCompleted) return;

        var status = statusCode;
        if (status == null) {
          // The stream closed before delivering a response (no `:status`
          // header). Treat it as a transport failure so the network
          // diagnostics classify it as retryable, rather than fabricating a
          // bogus status code.
          completer.completeError(const HttpException(
              'HTTP/2 stream closed before any response headers were received'));
          return;
        }

        completer.complete(_buildHttp2Response(status, bytes, responseHeaders));
      },
      cancelOnError: true,
    );

    if (body != null) {
      try {
        stream.outgoingMessages.add(DataStreamMessage(body, endStream: true));
      } catch (e) {
        // Sending the body failed (e.g. the connection died mid-send). Tear
        // down the half-open stream and surface a transport error.
        try {
          stream.terminate();
        } catch (_) {}
        if (!completer.isCompleted) {
          completer.completeError((e is HttpException || e is SocketException)
              ? e
              : HttpException('HTTP/2 send failed: $e'));
        }
      }
    }
    try {
      await stream.outgoingMessages.close();
    } catch (_) {}

    try {
      return await completer.future;
    } finally {
      await subscription.cancel();
    }
  }

  /// Builds a [Response] from an HTTP/2 stream, transparently gunzipping the
  /// body when the response is `content-encoding: gzip` (parity with the
  /// HTTP/1.1 path, where `HttpClient.autoUncompress` does this automatically).
  Response _buildHttp2Response(
      int statusCode, List<int> bytes, Map<String, List<String>> headers) {
    var encoding = headers['content-encoding'];
    var isGzip = encoding != null &&
        encoding.any((value) => value.trim().toLowerCase() == 'gzip');

    if (isGzip) {
      try {
        bytes = gzip.decode(bytes);
        // Drop now-inaccurate metadata, mirroring HttpClient's behaviour.
        headers = {...headers}
          ..remove('content-encoding')
          ..remove('content-length');
      } catch (_) {
        // Not actually gzip-encoded — fall through with the raw bytes.
      }
    }

    return Response.fromHttp2(bytes, statusCode, headers);
  }
}
