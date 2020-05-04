import 'dart:async';

import '../effect.dart';
import '../state_machine.dart';

class SendEffect<State, Context> extends Effect<State, Context> {
  String event;
  dynamic payload;
  Duration after;

  SendEffect(this.event, {this.payload, this.after});

  Timer _timer;

  @override
  void execute(
      {State exiting,
      State entering,
      String event,
      payload,
      String edge,
      StateMachine machine,
      Updater<Context> updater}) {
    if (event == '_enter') {
      if (after != null) {
        _timer = Timer(after, () => _send(machine));
      } else {
        _send(machine);
      }
    } else if (event == '_exit') {
      if (after != null) {
        _timer.cancel();
      }
    }
  }

  void _send(StateMachine machine) {
    machine.send(event, payload);
  }
}
