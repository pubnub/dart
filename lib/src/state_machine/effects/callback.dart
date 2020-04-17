import '../effect.dart';
import '../state_machine.dart';

class CallbackContext<State, Context> {
  State exiting;
  State entering;
  Symbol event;
  dynamic payload;
  Symbol edge;
  Context context;
  StateMachine<State, Context> machine;
  Updater<Context> update;

  CallbackContext(this.exiting, this.entering, this.event, this.payload,
      this.edge, this.context, this.machine, this.update);
}

typedef Callback<State, Context> = void Function(
    CallbackContext<State, Context> ctx);

class CallbackEffect<State, Context> extends Effect<State, Context> {
  covariant Callback<State, Context> callback;
  CallbackEffect(this.callback);

  @override
  void execute(
      {State exiting,
      State entering,
      Symbol event,
      payload,
      Symbol edge,
      StateMachine machine,
      Updater<Context> updater}) {
    callback(CallbackContext(exiting, entering, event, payload, edge,
        machine.context, machine, updater));
  }
}
