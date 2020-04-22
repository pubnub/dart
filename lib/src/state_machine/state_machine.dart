library pubnub.state_machine;

import 'dart:async';

import 'change.dart';
import 'effect.dart';

export 'blueprint.dart';
export 'change.dart';
export 'effect.dart';

class StateMachine<State, Context> {
  State _currentState;
  State get state => _currentState;

  Context _currentContext;
  Context get context => _currentContext;

  StateMachine parent;

  final Map<String, Map<List<State>, State>> _defs = {};
  final Map<State, Map<String, List<Effect<State, Context>>>> _effects = {};
  final Map<String, StateMachine> _submachines = {};
  final Map<String, StreamSubscription> _subs = {};

  final StreamController<TransitionChange<dynamic, dynamic, dynamic>>
      _transitionsController = StreamController.broadcast();
  Stream<TransitionChange<dynamic, dynamic, dynamic>> get transitions =>
      _transitionsController.stream;

  StateMachine();

  void register(String name, StateMachine machine) {
    _submachines[name] = machine;
    _subs[name] = machine.transitions.listen((t) {
      _transitionsController.add(t);
    });
  }

  void unregister(String name, StateMachine machine) {
    _subs[name].cancel();
    _submachines[name] = null;
  }

  StateMachine get(String name) => _submachines[name];

  void _report(State previous, State next, String edge, String event,
      [dynamic payload]) {
    var actions = _effects[state] ?? {};
    var effects = actions[edge] ?? [];

    for (var effect in effects) {
      effect.execute(
        exiting: previous,
        entering: next,
        edge: edge,
        event: event,
        payload: payload,
        machine: this,
        updater: ((Context ctx) => _currentContext = ctx),
      );
    }
  }

  void _reportPass(String event, [dynamic payload]) {}

  void _transition(State to, String event, [dynamic payload]) {
    _transitionsController.add(TransitionChange<State, Context, dynamic>()
      ..machine = this
      ..event = event
      ..from = _currentState
      ..to = to
      ..payload = payload);

    var previousState = _currentState;
    var nextState = to;

    _report(previousState, nextState, 'exits', event, payload);
    _currentState = to;
    _report(previousState, nextState, 'enters', event, payload);
  }

  void enter(State state, [dynamic payload]) =>
      _transition(state, '_enter', payload);
  void exit([dynamic payload]) => _transition(null, '_exit', payload);

  bool send(String event, [dynamic payload]) {
    var legalStates = _defs[event];

    if (legalStates == null) {
      _reportPass(event, payload);
      return false;
    }

    var nextStateEntry = legalStates.entries.firstWhere(
        (entry) => entry.key.contains(_currentState),
        orElse: () => null);

    if (nextStateEntry == null) {
      _reportPass(event, payload);
      return false;
    }

    var nextState = nextStateEntry.value;

    _transition(nextState, event, payload);

    return true;
  }

  void define(String event, {List<State> from, State to}) {
    _defs[event] ??= {};
    _defs[event][from] = to;
  }

  void when(State state, String edge, Effect<State, Context> effect) {
    _effects[state] ??= {};
    _effects[state][edge] ??= [];
    _effects[state][edge].add(effect);
  }
}
