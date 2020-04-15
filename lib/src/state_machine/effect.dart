import 'state_machine.dart';

typedef Context Updater<Context>(Context ctx);

abstract class Effect<State, Context> {
  void execute(
      {State exiting,
      State entering,
      Symbol event,
      dynamic payload,
      Symbol edge,
      StateMachine machine,
      Updater<Context> updater});
}
