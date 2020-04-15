import 'state_machine.dart';

class ContextChange<ContextType> {
  ContextType from;
  ContextType to;

  ContextChange(this.from, this.to);

  @override
  String toString() {
    return 'From: $from\nTo: $to';
  }
}

class TransitionChange<State, Context, Payload> {
  StateMachine<State, Context> machine;
  State from;
  State to;

  Symbol event;
  Payload payload;

  @override
  String toString() {
    return 'Transition of {$machine} [$event] (from $from, to $to) with $payload';
  }
}
