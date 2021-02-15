import 'dart:async';

import 'package:pubnub/core.dart';
import 'event.dart';

final _logger = injectLogger('pubnub.core.supervisor.signals');

class Signals {
  final StreamController<SupervisorEvent> _controller =
      StreamController.broadcast();
  Stream<SupervisorEvent> get _stream => _controller.stream;

  bool _isNetworkAvailable = true;

  /// @nodoc
  void notify(SupervisorEvent event) {
    if (_isNetworkAvailable == true && event is NetworkIsDownEvent) {
      _logger.verbose('Signaled that network is down.');
      _isNetworkAvailable = false;

      _controller.add(event);
    }

    if (_isNetworkAvailable == false && event is NetworkIsUpEvent) {
      _logger.verbose('Signaled that network is up.');
      _isNetworkAvailable = true;

      _controller.add(event);
    }
  }

  /// Will emit `void` when detected that network is down.
  Stream<void> get networkIsDown =>
      _stream.where((event) => event is NetworkIsDownEvent);

  /// Will emit `void` when detected that network is up.
  Stream<void> get networkIsUp =>
      _stream.where((event) => event is NetworkIsUpEvent);

  /// Will emit `bool` whether the network is connected or not when its status changes.
  Stream<bool> get networkIsConnected => _stream.map((event) {
        if (event is NetworkIsUpEvent) {
          return true;
        } else if (event is NetworkIsDownEvent) {
          return false;
        }

        return _isNetworkAvailable;
      });
}
