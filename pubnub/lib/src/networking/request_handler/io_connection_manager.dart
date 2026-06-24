import 'dart:async';
import 'dart:io';

import 'package:http2/transport.dart';
import 'package:pubnub/core.dart';

final _logger = injectLogger('pubnub.networking.http2');

/// Per-[NetworkingModule] HTTP/2 connection managers.
///
/// Keyed by the module instance so that connections (and their TLS/ALPN state,
/// bad-certificate policy, etc.) are never shared across unrelated modules.
final Expando<Http2ConnectionManager> _managers =
    Expando('pubnub.networking.http2.managers');

/// Returns the [Http2ConnectionManager] associated with [moduleKey], creating
/// it lazily on first use.
Http2ConnectionManager http2ManagerFor(Object moduleKey) =>
    _managers[moduleKey] ??= Http2ConnectionManager();

/// Closes and forgets the HTTP/2 connection manager for [moduleKey], if any.
///
/// Called from `NetworkingModule.dispose()` to deterministically release any
/// open connections and their timers instead of waiting for the idle reaper.
void disposeHttp2Manager(Object moduleKey) {
  _managers[moduleKey]?.close();
  _managers[moduleKey] = null;
}

/// HTTP/2 header names that are connection-specific and MUST NOT be forwarded
/// on an HTTP/2 request (RFC 7540 §8.1.2.2). `host` is replaced by `:authority`.
const _droppedHttp2Headers = {
  'connection',
  'keep-alive',
  'proxy-connection',
  'transfer-encoding',
  'upgrade',
  'host',
};

/// Builds the `:path` pseudo-header value for an HTTP/2 request.
///
/// [uri] is expected to already have any query transformations applied (e.g.
/// the `+` → `%20` substitution performed by the request handler).
String buildHttp2Path(Uri uri) {
  var path = uri.path.isEmpty ? '/' : uri.path;
  if (uri.hasQuery && uri.query.isNotEmpty) {
    path = '$path?${uri.query}';
  }
  return path;
}

/// Builds the ordered HTTP/2 header list for a request.
///
/// Pseudo-headers are emitted first (as required by the spec), all header names
/// are lower-cased, and connection-specific headers are dropped.
List<Header> buildHttp2Headers({
  required String method,
  required Uri uri,
  required Map<String, String> headers,
}) {
  final authority = uri.port == 443 ? uri.host : '${uri.host}:${uri.port}';

  final result = <Header>[
    Header.ascii(':method', method),
    Header.ascii(':scheme', uri.scheme.isEmpty ? 'https' : uri.scheme),
    Header.ascii(':authority', authority),
    Header.ascii(':path', buildHttp2Path(uri)),
  ];

  headers.forEach((name, value) {
    final lower = name.toLowerCase();
    if (_droppedHttp2Headers.contains(lower)) return;
    if (lower == 'te' && value.toLowerCase() != 'trailers') return;
    result.add(Header.ascii(lower, value));
  });

  return result;
}

/// A live HTTP/2 stream handed back to the request handler, paired with the
/// owning connection so the handler can signal completion.
class Http2Stream {
  final ClientTransportStream stream;
  final _ConnectionHolder _holder;

  Http2Stream._(this.stream, this._holder);

  /// Marks this request as finished so the owning connection can update its
  /// active-stream accounting and schedule idle reaping.
  void done() => _holder._endRequest();
}

/// Manages multiplexed HTTP/2 connections for a single networking module.
///
/// Two connections are kept per origin: a shared one for transactional requests
/// and a dedicated one for long-poll subscribe requests, so that tearing down
/// the long-lived subscribe connection cannot disrupt in-flight transactional
/// requests (and vice-versa).
class Http2ConnectionManager {
  static const _idleTimeout = Duration(seconds: 30);
  static const _pingInterval = Duration(seconds: 30);

  /// In-flight or resolved connection futures, keyed by `host:port:purpose`.
  /// A future resolves to `null` when the origin negotiated HTTP/1.1 via ALPN.
  final Map<String, Future<_ConnectionHolder?>> _pending = {};

  /// Origins (`host:port`) known not to negotiate HTTP/2 via ALPN.
  final Set<String> _nonHttp2Hosts = {};

  /// Opens an HTTP/2 stream for a request, or returns `null` when the origin
  /// does not support HTTP/2 (caller should use the HTTP/1.1 path).
  ///
  /// Performs a single transparent reconnect if a pooled connection turns out
  /// to be dead before any request bytes are sent.
  Future<Http2Stream?> openStream(
    Uri origin, {
    required bool isSubscribe,
    required Duration connectTimeout,
    required List<Header> headers,
    required bool endStream,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final holder = await _acquire(origin,
          isSubscribe: isSubscribe, connectTimeout: connectTimeout);
      if (holder == null) return null;

      try {
        final stream = holder._startRequest(headers, endStream: endStream);
        return Http2Stream._(stream, holder);
      } on StateError {
        // Connection was racing into a finishing/terminated state. Evict it and
        // retry once on a fresh connection (no bytes have been sent yet).
        holder._dispose();
      }
    }

    return null;
  }

  Future<_ConnectionHolder?> _acquire(
    Uri origin, {
    required bool isSubscribe,
    required Duration connectTimeout,
  }) async {
    final originKey = '${origin.host}:${origin.port}';
    if (_nonHttp2Hosts.contains(originKey)) return null;

    final key = '$originKey:${isSubscribe ? 'subscribe' : 'tx'}';

    final existing = _pending[key];
    if (existing != null) {
      try {
        final holder = await existing;
        if (holder == null) return null; // origin uses HTTP/1.1
        if (holder.isUsable) return holder;
      } catch (_) {
        // Fall through to reconnect.
      }
      if (!identical(_pending[key], existing)) {
        // While we awaited, another caller already replaced the dead
        // connection. Reuse their attempt instead of opening a duplicate.
        return _acquire(origin,
            isSubscribe: isSubscribe, connectTimeout: connectTimeout);
      }
      unawaited(_pending.remove(key));
    }

    // A concurrent attempt may have discovered the origin is HTTP/1.1-only.
    if (_nonHttp2Hosts.contains(originKey)) return null;

    final future = _connect(origin, key, connectTimeout);
    _pending[key] = future;
    try {
      final holder = await future;
      // Non-h2 result: drop the pending entry, future callers use [_nonHttp2Hosts].
      if (holder == null && identical(_pending[key], future)) {
        unawaited(_pending.remove(key));
      }
      return holder;
    } catch (e) {
      if (identical(_pending[key], future)) unawaited(_pending.remove(key));
      rethrow;
    }
  }

  Future<_ConnectionHolder?> _connect(
      Uri origin, String key, Duration connectTimeout) async {
    final socket = await SecureSocket.connect(
      origin.host,
      origin.port,
      supportedProtocols: const ['h2', 'http/1.1'],
    ).timeout(connectTimeout);

    if (socket.selectedProtocol != 'h2') {
      _logger.info(
          'ALPN negotiated "${socket.selectedProtocol ?? 'none'}" with ${origin.host}:${origin.port}; using HTTP/1.1.');
      _nonHttp2Hosts.add('${origin.host}:${origin.port}');
      try {
        await socket.close();
      } catch (_) {}
      socket.destroy();
      return null;
    }

    _logger.info(
        'ALPN negotiated "h2" with ${origin.host}:${origin.port}; using HTTP/2.');
    final connection = ClientTransportConnection.viaSocket(socket);
    return _ConnectionHolder(
      connection,
      socket,
      idleTimeout: _idleTimeout,
      pingInterval: _pingInterval,
      onDead: (holder) => _evict(key, holder),
    );
  }

  void _evict(String key, _ConnectionHolder holder) {
    final pending = _pending[key];
    if (pending == null) return;
    unawaited(pending.then((resolved) {
      if (identical(resolved, holder) && identical(_pending[key], pending)) {
        _pending.remove(key);
      }
    }).catchError((_) {}));
  }

  /// Disposes every managed connection and clears all cached state.
  void close() {
    final connections = _pending.values.toList();
    _pending.clear();
    _nonHttp2Hosts.clear();
    for (final connection in connections) {
      unawaited(
          connection.then((holder) => holder?._dispose()).catchError((_) {}));
    }
  }
}

/// Wraps a single multiplexed [ClientTransportConnection], tracking active
/// streams, pinging while busy, and reaping itself when idle or dead.
class _ConnectionHolder {
  final ClientTransportConnection connection;
  final Socket socket;
  final Duration idleTimeout;
  final Duration pingInterval;
  final void Function(_ConnectionHolder holder) onDead;

  int _active = 0;
  bool _disposed = false;
  bool _pinging = false;
  Timer? _idleTimer;
  Timer? _pingTimer;

  _ConnectionHolder(
    this.connection,
    this.socket, {
    required this.idleTimeout,
    required this.pingInterval,
    required this.onDead,
  }) {
    _pingTimer = Timer.periodic(pingInterval, (_) => _ping());
    _scheduleIdle();
  }

  bool get isUsable => !_disposed && connection.isOpen;

  ClientTransportStream _startRequest(List<Header> headers,
      {required bool endStream}) {
    final stream = connection.makeRequest(headers, endStream: endStream);
    _active++;
    _idleTimer?.cancel();
    return stream;
  }

  void _endRequest() {
    if (_active > 0) _active--;

    // Never tear down the connection while other multiplexed streams are still
    // in flight — that would abort siblings sharing this connection.
    if (_active > 0) return;

    if (!connection.isOpen) {
      _dispose();
    } else {
      _scheduleIdle();
    }
  }

  void _scheduleIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, () {
      if (_active == 0) _dispose();
    });
  }

  Future<void> _ping() async {
    // Skip if disposed, idle, or a previous ping is still outstanding (avoids
    // overlapping pings piling up on a stalled connection).
    if (_disposed || _active == 0 || _pinging) return;
    _pinging = true;
    try {
      // Bound the ping: a half-open connection (no RST) would otherwise never
      // complete, leaving the connection wrongly considered alive.
      await connection.ping().timeout(pingInterval);
    } catch (_) {
      _dispose();
    } finally {
      _pinging = false;
    }
  }

  void _dispose() {
    if (_disposed) return;
    _disposed = true;
    _idleTimer?.cancel();
    _pingTimer?.cancel();
    onDead(this);
    unawaited(_closeQuietly());
  }

  Future<void> _closeQuietly() async {
    try {
      await connection.finish();
    } catch (_) {}
    try {
      await socket.close();
    } catch (_) {}
    try {
      socket.destroy();
    } catch (_) {}
  }
}
