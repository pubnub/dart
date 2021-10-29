import 'package:pubnub/core.dart';

import 'cbor.dart';
import 'resource.dart';

/// Token returned by the PAM.
///
/// {@category Access Manager}
class Token {
  final String _stringToken;

  Map<String, dynamic>? _memoizedData;
  Map<String, dynamic>? get _data {
    if (_memoizedData == null) {
      var object = parseToken(_stringToken);

      _memoizedData = {
        'version': object['v'],
        'timetoken': object['t'],
        'ttl': object['ttl'],
        'authorizedUUID': object['uuid'],
        'signature': object['sig'],
        'meta': object['meta']
      };

      var resources = <Resource>[];
      var patterns = <Resource>[];

      for (var typeEntry in object['res'].cast<String, dynamic>().entries) {
        var type = getResourceTypeFromString(typeEntry.key);

        for (var resourceEntry in typeEntry.value.entries) {
          resources.add(Resource(type,
              name: resourceEntry.key, bit: resourceEntry.value));
        }
      }

      for (var typeEntry in object['pat'].cast<String, dynamic>().entries) {
        var type = getResourceTypeFromString(typeEntry.key);

        for (var resourceEntry in typeEntry.value.entries) {
          patterns.add(Resource(type,
              pattern: resourceEntry.key, bit: resourceEntry.value));
        }
      }

      _memoizedData!['resources'] = resources;
      _memoizedData!['patterns'] = patterns;
    }

    return _memoizedData;
  }

  /// Version of the token encoding.
  int get version => _data!['version'] as int;

  /// Time-to-live for this token.
  int get ttl => _data!['ttl'] as int;

  /// Timetoken that is the start time for [ttl].
  Timetoken get timetoken => Timetoken(BigInt.from(_data!['timetoken']));

  /// authorized UUID which is authorized to use this token to make requests
  String? get authorizedUUID => _data!['authorizedUUID'];

  /// Meta data attached to this token.
  dynamic get meta => _data!['meta'];

  /// Signature encoded as base64 string.
  String get signature => _data!['signature'] as String;

  /// All resources attached to this token.
  List<Resource> get resources => (_data!['resources']);

  /// All patterns attached to this token.
  List<Resource> get patterns => (_data!['patterns']);

  Token(this._stringToken);

  @override
  String toString() => _stringToken;
}
