import 'state_machine.dart';

typedef Updater<Context> = Context Function(Context ctx);

abstract class Effect<State, Context> {
  void execute(
      {State exiting,
      State entering,
      String event,
      dynamic payload,
      String edge,
      StateMachine machine,
      Updater<Context> updater});
}
