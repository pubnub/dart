import 'package:pubnub/src/core/core.dart';

import 'cbor.dart';
import 'resource.dart';

/// Token returned by the PAM.
class Token {
  final String _stringToken;

  Map<String, dynamic> _memoizedData;
  Map<String, dynamic> get _data {
    if (_memoizedData == null) {
      var object = parseToken(_stringToken);

      print(object);

      _memoizedData = {
        'v': object['v'],
        't': object['t'],
        'ttl': object['ttl'],
        'sig': object['sig'],
        'meta': object['meta']
      };

      var resources = [];

      for (var typeEntry in object['res'].cast<String, dynamic>().entries) {
        var type = getResourceTypeFromString(typeEntry.key);

        for (var resourceEntry in typeEntry.value.entries) {
          resources
              .add(Resource(type, resourceEntry.key, bit: resourceEntry.value));
        }
      }

      for (var typeEntry in object['pat'].cast<String, dynamic>().entries) {
        var type = getResourceTypeFromString(typeEntry.key);

        for (var resourceEntry in typeEntry.value.entries) {
          resources.add(Resource(type, RegExp(resourceEntry.key),
              bit: resourceEntry.value));
        }
      }

      _memoizedData['resources'] = resources;
    }

    return _memoizedData;
  }

  /// Version of the token encoding.
  int get version => _data['v'] as int;

  /// Time-to-live for this token.
  int get ttl => _data['ttl'] as int;

  /// Timetoken that is the start time for [ttl].
  Timetoken get timetoken => Timetoken(_data['t'] as int);

  /// Meta data attached to this token.
  dynamic get meta => _data['meta'];

  /// Signature encoded as base64 string.
  String get signature => _data['sig'] as String;

  /// All resources attached to this token.
  List<Resource> get resources => (_data['resources'] as List<Resource>)
      .where((resource) => resource.name is String)
      .toList();

  /// All patterns attached to this token.
  List<Resource> get patterns => (_data['resources'] as List<Resource>)
      .where((resource) => resource.name is RegExp)
      .toList();

  Token(this._stringToken);

  @override
  String toString() => _stringToken;
}
