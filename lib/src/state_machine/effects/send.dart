import '../effect.dart';
import '../state_machine.dart';

class SendEffect<State, Context> extends Effect<State, Context> {
  Symbol event;
  dynamic payload;
  Duration after;

  SendEffect(this.event, {this.payload, this.after});

  @override
  void execute(
      {State exiting,
      State entering,
      Symbol event,
      payload,
      Symbol edge,
      StateMachine machine,
      Updater<Context> updater}) {
    if (after != null) {
      Future.delayed(after, () => _send(machine));
    } else {
      _send(machine);
    }
  }

  void _send(StateMachine machine) {
    machine.send(event, payload);
  }
}
