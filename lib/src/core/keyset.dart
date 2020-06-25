import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'crypto/cipher_key.dart';
import 'uuid.dart';

class KeysetException extends PubNubException {
  KeysetException(String message) : super(message);
}

class KeysetStore {
  final Map<String, Keyset> _store = {};
  String _defaultName;

  /// Returns a list of all keysets in this store
  List<Keyset> get keysets => _store.values.toList();

  /// Adds a [keyset] named [name] to the store.
  ///
  /// If [useAsDefault] is true, then it will be used as a default keyset.
  Keyset add(Keyset keyset,
      {@required String name, bool useAsDefault = false}) {
    if (_store.containsKey(name)) {
      throw KeysetException('Cannot add two keysets with the same name');
    }
    _store[name] = keyset;

    if (useAsDefault) {
      _defaultName = name;
    }

    return keyset;
  }

  Keyset remove(String name) {
    if (name == _defaultName) {
      _defaultName = null;
    }

    if (_store.containsKey(name)) {
      return _store.remove(name);
    }

    return null;
  }

  /// Obtain a keyset named [name].
  ///
  /// If [defaultIfNameIsNull] is true, then if [name] is null
  /// it will return a default keyset. If [throwOnNull] is false,
  /// instead of throwing it will return null.
  Keyset get(String name,
      {bool defaultIfNameIsNull = false, bool throwOnNull = true}) {
    if (name == null) {
      if (defaultIfNameIsNull) {
        return _getDefault(throwOnNull: throwOnNull);
      } else {
        if (throwOnNull) {
          throw KeysetException('Keyset name cannot be null');
        } else {
          return null;
        }
      }
    }

    if (!_store.containsKey(name)) {
      if (throwOnNull) {
        throw KeysetException(
            'Unknown keyset name, please add the keyset to the store first');
      } else {
        return null;
      }
    }

    return _store[name];
  }

  /// Iterate over each keyset.
  void forEach(void Function(String, Keyset) callback) {
    for (var entry in _store.entries) {
      callback(entry.key, entry.value);
    }
  }

  Keyset _getDefault({bool throwOnNull}) {
    if (_defaultName != null) {
      return _store[_defaultName];
    } else {
      if (throwOnNull) {
        throw KeysetException('Default keyset has not been defined');
      } else {
        return null;
      }
    }
  }
}

/// Represents a configuration for a given subscribe key.
class Keyset {
  /// Subscribe key.
  final String subscribeKey;

  /// Publish key.
  final String publishKey;

  /// Secret key used for administrative tasks.
  final String secretKey;

  /// If PAM is enabled, authentication key is required to access channels.
  final String authKey;

  /// Used for message encryption.
  final CipherKey cipherKey;

  /// UUID used in MAU pricing.
  final UUID uuid;

  /// A map of settings that can be set and used by specific DX extensions.
  Map<String, dynamic> settings = {};

  Keyset(
      {@required this.subscribeKey,
      this.publishKey,
      this.secretKey,
      this.authKey,
      this.cipherKey,
      this.uuid});
}
