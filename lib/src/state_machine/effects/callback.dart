import '../effect.dart';
import '../state_machine.dart';

class CallbackContext<State, Context> {
  State exiting;
  State entering;
  String event;
  dynamic payload;
  String edge;
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
      String event,
      payload,
      String edge,
      StateMachine machine,
      Updater<Context> updater}) {
    callback(CallbackContext(exiting, entering, event, payload, edge,
        machine.context, machine, updater));
  }
}
