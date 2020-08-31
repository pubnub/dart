import 'dart:async';

import '../core.dart';
import 'event.dart';
import 'fiber.dart';

export 'event.dart';
export 'fiber.dart';

final _logger = injectLogger('pubnub.core.supervisor');

abstract class Diagnostic {
  const Diagnostic();
}

abstract class Strategy {
  List<Resolution> resolve(Fiber fiber, Diagnostic diagnostic);
}

typedef DiagnosticHandler = Diagnostic Function(dynamic exception);

class SupervisorModule {
  final Set<DiagnosticHandler> _handlers = {};
  final Set<Strategy> _strategies = {};

  final StreamController<SupervisorEvent> _events =
      StreamController.broadcast();

  bool _isNetworkUp = true;

  Stream<SupervisorEvent> get events => _events.stream;

  void registerDiagnostic(DiagnosticHandler handler) {
    _handlers.add(handler);
  }

  void registerStrategy(Strategy strategy) {
    _strategies.add(strategy);
  }

  void notify(SupervisorEvent event) {
    if (_isNetworkUp && event is NetworkIsDownEvent) {
      _isNetworkUp = false;
      _logger.warning('Detected that network is down.');
      _events.add(event);
    } else if (_isNetworkUp == false && event is NetworkIsUpEvent) {
      _isNetworkUp = true;
      _logger.warning('Detected that network is up.');
      _events.add(event);
    }
  }

  Diagnostic runDiagnostics(Fiber fiber, Exception exception) {
    return _handlers
        .map((handler) => handler(exception))
        .firstWhere((diagnostic) => diagnostic != null, orElse: () => null);
  }

  List<Resolution> runStrategies(Fiber fiber, Diagnostic diagnostic) {
    return _strategies
        .map((strategy) => strategy.resolve(fiber, diagnostic))
        .firstWhere((resolutions) => resolutions != null, orElse: () => []);
  }
}
