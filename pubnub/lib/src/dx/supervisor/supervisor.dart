import 'package:pubnub/core.dart';

export '../../core/supervisor/signals.dart';

/// @nodoc
mixin SupervisorDx on Core {
  /// Internal signals.
  Signals get signals => supervisor.signals;

  /// Breaks up pending connections and restarts them.
  void reconnect() {
    supervisor.notify(NetworkIsDownEvent());
  }
}
