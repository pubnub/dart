import 'dart:async';

abstract class Cache {
  T get<T>(String key);

  void set<T>(String key, T value);

  StreamSubscription<T> follow<T>(String key, Stream<T> stream) {
    return stream.listen((value) => set(key, value));
  }
}

class SimpleCache extends Cache {
  final _storage = <String, dynamic>{};

  @override
  T get<T>(String key) {
    return _storage[key];
  }

  @override
  void set<T>(String key, T value) {
    _storage[key] = value;
  }
}
