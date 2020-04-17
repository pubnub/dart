import 'callback.dart';
import '../effect.dart';
import '../blueprint.dart';
import '../state_machine.dart';

typedef MachineCallback<S, C, SS, SC> = void Function(
    StateMachine<S, C> machine, StateMachine<SS, SC> submachine);
typedef MachineCallbackWithCtx<S, C, SS, SC> = void Function(
    CallbackContext<SS, SC> ctx,
    StateMachine<S, C> machine,
    StateMachine<SS, SC> submachine);

class MachineEffect<State, Context, SubState, SubContext>
    extends Effect<State, Context> {
  String name;
  Blueprint blueprint;

  MachineCallbackWithCtx<State, Context, SubState, SubContext> onExit;
  MachineCallbackWithCtx<State, Context, SubState, SubContext> onEnter;
  MachineCallback<State, Context, SubState, SubContext> onBuild;

  MachineEffect(this.name, this.blueprint,
      {this.onExit, this.onEnter, this.onBuild});

  @override
  void execute(
      {State exiting,
      State entering,
      Symbol event,
      payload,
      Symbol edge,
      StateMachine machine,
      Updater<Context> updater}) {
    if (edge == #enters) {
      var submachine = blueprint.build(machine);

      machine.register(name, submachine);

      if (onBuild != null) onBuild(machine, submachine);

      submachine.when(null, #exits, CallbackEffect<SubState, SubContext>((ctx) {
        if (onEnter != null) onEnter(ctx, machine, submachine);
      }));

      submachine.when(null, #enters,
          CallbackEffect<SubState, SubContext>((ctx) {
        if (onExit != null) onExit(ctx, machine, submachine);
      }));
    } else if (edge == #exits) {
      var submachine = machine.get(name);

      if (submachine.state != null) {
        submachine.exit();
      }

      machine.unregister(name, submachine);
    }
  }
}
