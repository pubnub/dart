import 'event.dart';
import 'fiber.dart';
import 'resolution.dart';
import 'signals.dart';

export 'event.dart';
export 'fiber.dart';
export 'resolution.dart';
export 'signals.dart';

abstract class Diagnostic {
  const Diagnostic();
}

abstract class Strategy {
  List<Resolution>? resolve(Fiber fiber, Diagnostic diagnostic);
}

typedef DiagnosticHandler = Diagnostic? Function(Object exception);

class SupervisorModule {
  final Set<DiagnosticHandler> _handlers = {};
  final Set<Strategy> _strategies = {};

  final Signals signals = Signals();

  void registerDiagnostic(DiagnosticHandler handler) {
    _handlers.add(handler);
  }

  void registerStrategy(Strategy strategy) {
    _strategies.add(strategy);
  }

  void notify(SupervisorEvent event) => signals.notify(event);

  Diagnostic? runDiagnostics(Fiber fiber, Object exception) {
    return _handlers
        .map((handler) => handler(exception))
        .firstWhere((diagnostic) => diagnostic != null, orElse: () => null);
  }

  List<Resolution>? runStrategies(Fiber fiber, Diagnostic diagnostic) {
    return _strategies
        .map((strategy) => strategy.resolve(fiber, diagnostic))
        .firstWhere((resolutions) => resolutions != null, orElse: () => null);
  }
}
