import '../effect.dart';
import '../state_machine.dart';

class ExitEffect<State, Context> extends Effect<State, Context> {
  Duration after;
  bool withPayload;

  ExitEffect({this.after, this.withPayload});

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
      Future.delayed(after, () => _exit(machine, payload));
    } else {
      _exit(machine, payload);
    }
  }

  void _exit(StateMachine machine, dynamic payload) {
    if (withPayload == true) {
      machine.exit(payload);
    } else {
      machine.exit();
    }
  }
}
