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

      _memoizedData!['resources'] = _decodeResources(object['res'], false);
      _memoizedData!['patterns'] = _decodeResources(object['pat'], true);
      _memoizedData!['projections'] = _decodeProjections(object['meta']);
      _memoizedData!['categories'] = _decodeCategories(object['cat']);
    }

    return _memoizedData;
  }

  /// Decodes a `res` or `pat` section of a parsed token into resources.
  ///
  /// Scopes that are not recognized are skipped so that scopes introduced by
  /// the server in the future do not fail the whole parse.
  static List<Resource> _decodeResources(dynamic section, bool isPattern) {
    var result = <Resource>[];

    if (section is! Map) return result;

    for (var typeEntry in section.cast<String, dynamic>().entries) {
      var type = getResourceTypeFromString(typeEntry.key);
      if (type == null) continue;

      if (typeEntry.value is! Map) continue;

      for (var resourceEntry in (typeEntry.value as Map).entries) {
        result.add(Resource(type,
            name: isPattern ? null : resourceEntry.key as String,
            pattern: isPattern ? resourceEntry.key as String : null,
            bit: resourceEntry.value as int));
      }
    }

    return result;
  }

  /// Decodes the `cat` section of a parsed token into category-level
  /// permissions.
  ///
  /// Unknown categories and malformed entries are skipped so that categories
  /// introduced by the server in the future do not fail the whole parse.
  static List<Resource> _decodeCategories(dynamic section) {
    var result = <Resource>[];

    if (section is! Map) return result;

    for (var entry in section.entries) {
      var key = entry.key;
      var bit = entry.value;
      if (key is! String || bit is! int) continue;

      var type = getResourceTypeFromString(key);
      if (type == null || !type.supportsCategory) continue;

      result.add(Resource(type, bit: bit));
    }

    return result;
  }

  /// Decodes the `pn-projections` entry of the token metadata.
  ///
  /// Composite keys are of the form `<datasync scope>:<resource id>`. Both the
  /// scope and the id can contain `:`, so the known scope prefixes are matched
  /// instead of splitting on the separator.
  static List<Projection> _decodeProjections(dynamic meta) {
    if (meta is! Map) return const [];

    var encoded = meta['pn-projections'];
    if (encoded is! Map) return const [];

    var result = <Projection>[];

    void decodeSection(dynamic section, bool isPattern) {
      if (section is! Map) return;

      for (var entry in section.entries) {
        var key = entry.key;
        if (key is! String || entry.value is! String) continue;

        for (var type
            in ResourceType.values.where((type) => type.supportsProjection)) {
          var prefix = '${type.projectionScope}:';
          if (!key.startsWith(prefix)) continue;

          var id = key.substring(prefix.length);
          if (id.isEmpty) break;

          result.add(Projection(type,
              name: isPattern ? null : id,
              pattern: isPattern ? id : null,
              projection: entry.value as String));
          break;
        }
      }
    }

    decodeSection(encoded['res'], false);
    decodeSection(encoded['pat'], true);

    return result;
  }

  /// Version of the token encoding.
  int get version => _data!['version'] as int;

  /// Time-to-live for this token.
  int get ttl => _data!['ttl'] as int;

  /// Timetoken that is the start time for [ttl].
  Timetoken get timetoken => Timetoken.from(_data!['timetoken']);

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

  /// All DataSync projections attached to this token.
  ///
  /// Empty when the token carries no projection assignments.
  List<Projection> get projections => (_data!['projections']);

  /// All category-level permissions attached to this token.
  ///
  /// Empty when the token carries no category grants.
  List<Resource> get categories => (_data!['categories']);

  Token(this._stringToken);

  @override
  String toString() => _stringToken;
}
