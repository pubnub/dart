import 'dart:async';
import 'dart:convert';
import 'package:pool/pool.dart';
import 'package:pubnub/core.dart';

// Import existing fake_net to maintain compatibility
import 'fake_net.dart' as original;
export 'fake_net.dart'
    show MockException, MockRequest, MockResponse, Mock, MockBuilder;

/// Enhanced FakeRequestHandler that supports external URLs (S3, etc.)
class FakeCustomRequestHandler extends IRequestHandler {
  final EnhancedFakeNetworkingModule module;
  final original.Mock mock;
  final PoolResource resource;

  FakeCustomRequestHandler(this.module, this.mock, this.resource);

  @override
  Future<IResponse> response(Request request) {
    // Handle external URLs directly without prepareUri transformation
    Uri actualUri;
    Uri expectedUri;

    if (_isExternalUrl(request.uri ?? Uri())) {
      // For external URLs, use them as-is
      actualUri = request.uri ?? Uri();
      expectedUri = Uri.parse(mock.request.path);
    } else {
      // For PubNub URLs, use the original logic
      actualUri = prepareUri(module.getOrigin(), request.uri ?? Uri());
      expectedUri =
          prepareUri(module.getOrigin(), Uri.parse(mock.request.path));
    }

    var doesMethodMatch =
        mock.request.method.toUpperCase() == request.type.method.toUpperCase();

    String? body;
    var requestBody = request.body;
    if (requestBody is String) {
      body = requestBody;
    } else if (requestBody == null) {
      body = null;
    } else if (requestBody is Map<String, dynamic>) {
      // Handle form data for file uploads
      if (_isFileUploadRequest(requestBody)) {
        body = 'FILE_UPLOAD_DATA'; // Simplified representation
      } else {
        body = json.encode(requestBody);
      }
    } else {
      body = json.encode(requestBody);
    }

    String? mockBody;
    if (request.body is String) {
      mockBody = mock.request.body;
    } else if (request.body == null) {
      mockBody = null;
    } else if (mock.request.body == 'FILE_UPLOAD_DATA') {
      mockBody = 'FILE_UPLOAD_DATA'; // Match file upload representation
    } else {
      try {
        mockBody = json.encode(json.decode(mock.request.body));
      } catch (e) {
        mockBody = mock.request.body; // Use as-is if not JSON
      }
    }

    var doesBodyMatch = mockBody == body;
    var doesUriMatch = _compareUris(expectedUri, actualUri);

    return Future.microtask(() {
      resource.release();

      if (doesMethodMatch && doesBodyMatch && doesUriMatch) {
        if (![200, 204].contains(mock.response.statusCode)) {
          throw RequestFailureException(mock.response,
              statusCode: mock.response.statusCode);
        } else {
          return mock.response;
        }
      } else {
        var exceptionBody = '';

        if (!doesMethodMatch) {
          exceptionBody +=
              '\n* method:\n| EXPECTED: ${mock.request.method.toUpperCase()}\n| ACTUAL:   ${request.type.method.toUpperCase()}';
        }
        if (!doesUriMatch) {
          exceptionBody +=
              '\n* uri:\n| EXPECTED: $expectedUri\n| ACTUAL:   $actualUri';
        }
        if (!doesBodyMatch) {
          exceptionBody +=
              '\n* body:\n| EXPECTED:\n$mockBody\n| ACTUAL:\n$body';
        }

        throw original.MockException(
            'mock request does not match the expected request $exceptionBody');
      }
    });
  }

  @override
  void cancel([dynamic reason]) {}

  @override
  bool get isCancelled => false;

  /// Check if the URL is external (not PubNub)
  bool _isExternalUrl(Uri uri) {
    return uri.host.isNotEmpty && !uri.host.contains('pndsn.com');
  }

  /// Check if request contains file upload data
  bool _isFileUploadRequest(Map<String, dynamic> body) {
    return body.containsKey('file') ||
        body.containsKey('key') ||
        body.containsKey('bucket');
  }

  /// Compare two URIs ignoring query parameter ordering
  bool _compareUris(Uri expected, Uri actual) {
    // Compare scheme, host, port, and path
    if (expected.scheme != actual.scheme ||
        expected.host != actual.host ||
        expected.port != actual.port ||
        expected.path != actual.path) {
      return false;
    }

    // Compare query parameters (ignoring order)
    var expectedParams = expected.queryParameters;
    var actualParams = actual.queryParameters;

    if (expectedParams.length != actualParams.length) {
      return false;
    }

    for (var key in expectedParams.keys) {
      if (!actualParams.containsKey(key) ||
          expectedParams[key] != actualParams[key]) {
        return false;
      }
    }

    return true;
  }
}

/// Enhanced networking module that supports external URLs
class EnhancedFakeNetworkingModule implements INetworkingModule {
  final Pool _pool = Pool(2);
  static final List<original.Mock> _queue = [];

  EnhancedFakeNetworkingModule() {
    _queue.clear();
  }

  @override
  Future<IRequestHandler> handler() async {
    var resource = await _pool.request();

    if (_queue.isEmpty) {
      resource.release();
      throw original.MockException('set up the mock first');
    }

    return FakeCustomRequestHandler(this, _queue.removeAt(0), resource);
  }

  @override
  void register(Core core) {}

  @override
  Uri getOrigin() {
    return Uri(
      scheme: 'https',
      host: 'ps.pndsn.com',
      queryParameters: {'pnsdk': 'PubNub-Dart/${Core.version}'},
    );
  }

  /// Add a mock to the queue
  static void addMock(original.Mock mock) {
    _queue.add(mock);
  }

  /// Clear all mocks
  static void clearMocks() {
    _queue.clear();
  }

  /// Get current queue length
  static int get queueLength => _queue.length;
}

/// Enhanced when function that supports external URLs
original.MockBuilder whenExternal({
  required String method,
  required String path,
  Map<String, List<String>> headers = const {},
  dynamic body,
  original.MockRequest? request,
}) {
  return original.MockBuilder(EnhancedFakeNetworkingModule._queue,
      request ?? original.MockRequest(method, path, headers, body));
}
