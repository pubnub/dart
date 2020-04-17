import 'dart:async';

import 'package:collection/collection.dart';

final _comparator = DeepCollectionEquality.unordered();

class StateChange<KeyType, ValueType> {
  Map<KeyType, ValueType> before;
  Map<KeyType, ValueType> after;
}

typedef StateUpdateFunction<KeyType, ValueType> = Map<KeyType, ValueType>
    Function(Map<KeyType, ValueType> state);

class State<KeyType, ValueType> {
  Map<KeyType, ValueType> _state;

  final StreamController<StateChange<KeyType, ValueType>> _changes =
      StreamController.broadcast();
  Stream<StateChange<KeyType, ValueType>> get changes => _changes.stream;

  State();

  factory State.create(Map<KeyType, ValueType> initialState) {
    return State().._state = Map.from(initialState);
  }

  bool update(StateUpdateFunction<KeyType, ValueType> updater) {
    var oldState = {..._state};
    var newState = {..._state, ...updater(_state)};

    var hasChanged = !_comparator.equals(_state, newState);

    if (hasChanged) {
      _state = newState;
      _changes.add(StateChange()
        ..before = oldState
        ..after = newState);
    }

    return hasChanged;
  }

  ValueType get(KeyType key) => _state[key];

  @override
  String toString() => '$_state';
}
