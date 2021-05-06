import '../exceptions.dart';
import 'keyset.dart';

/// Represents a collection of [Keyset].
///
/// Keyset names must be unique and only one of them can be default.
class KeysetStore {
  final Map<String, Keyset> _store = {};
  String? _defaultName;

  /// Returns a list of all keysets in this store.
  List<Keyset> get keysets => _store.values.toList(growable: false);

  /// Default keyset.
  ///
  /// This getter will throw [KeysetException] if default keyset is not defined.
  Keyset get defaultKeyset {
    if (_defaultName == null || !_store.containsKey(_defaultName)) {
      throw KeysetException('Default keyset is not defined');
    }

    return _store[_defaultName]!;
  }

  /// Adds a [keyset] named [name] to the store.
  ///
  /// If [useAsDefault] is true, then it will be used as a default keyset.
  /// If a default keyset already exists, this keyset will be used as a new default.
  Keyset add(String name, Keyset keyset, {bool useAsDefault = false}) {
    if (_store.containsKey(name)) {
      throw KeysetException('Keyset "$name" already exists');
    }

    _store[name] = keyset;

    if (useAsDefault) {
      _defaultName = name;
    }

    return keyset;
  }

  /// Removes a keyset from this store.
  ///
  /// If this keyset was previously set as default, after removing this keyset the default will not be defined.
  Keyset? remove(String name) {
    if (name == _defaultName) {
      _defaultName = null;
    }

    if (_store.containsKey(name)) {
      return _store.remove(name);
    }

    return null;
  }

  /// Gets a defined keyset.
  ///
  /// If [name] is null, then the [defaultKeyset] is returned.
  /// If keyset is not found, [KeysetException] is thrown.
  Keyset operator [](String? name) {
    if (name == null) {
      return defaultKeyset;
    }

    if (!_store.containsKey(name)) {
      throw KeysetException('Keyset "$name" is not defined');
    }

    return _store[name]!;
  }

  /// Iterate over each keyset.
  void forEach(void Function(String, Keyset) callback) {
    for (var entry in _store.entries) {
      callback(entry.key, entry.value);
    }
  }
}
