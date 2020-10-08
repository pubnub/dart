import 'dart:async';
import 'package:meta/meta.dart';
import 'package:pedantic/pedantic.dart';

import '../logging/logging.dart';
import '../core.dart';
import 'event.dart';
import 'resolution.dart';

final _logger = injectLogger('pubnub.core.fiber');

typedef _FiberAction<T> = Future<T> Function();

class Fiber<T> {
  static int _id = 0;

  final int id;
  final Core _core;
  final _FiberAction<T> action;

  final bool isSubscribe = false;

  final _completer = Completer<T>();
  Future<T> get future => _completer.future;

  int tries = 0;

  Fiber(this._core, {@required this.action}) : id = _id++;

  Future<void> run() async {
    tries += 1;

    try {
      var result = await action();

      _completer.complete(result);

      _core.supervisor.notify(NetworkIsUpEvent());
    } catch (exception, stackTrace) {
      _logger.warning('An exception has occured while running a fiber.');
      var diagnostic = _core.supervisor.runDiagnostics(this, exception);

      if (diagnostic == null) {
        return _completer.completeError(exception, stackTrace);
      }

      _logger.silly('Possible reason found: $diagnostic');

      var resolutions = _core.supervisor.runStrategies(this, diagnostic);

      for (var resolution in resolutions) {
        if (resolution is FailResolution) {
          _completer.completeError(exception);
        } else if (resolution is DelayResolution) {
          await Future.delayed(resolution.delay);
        } else if (resolution is RetryResolution) {
          unawaited(Future.microtask(run));
        } else if (resolution is NetworkStatusResolution) {
          _core.supervisor.notify(
              resolution.isUp ? NetworkIsUpEvent() : NetworkIsDownEvent());
        }
      }
    }
  }
}
