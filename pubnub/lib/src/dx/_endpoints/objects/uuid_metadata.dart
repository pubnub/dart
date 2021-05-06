import 'package:pubnub/core.dart';

class GetAllUuidMetadataParams extends Parameters {
  Keyset keyset;
  Set<String>? include;
  int? limit;
  String? start;
  String? end;
  bool? includeCount;
  String? filter;
  Set<String>? sort;

  GetAllUuidMetadataParams(this.keyset,
      {this.limit,
      this.include,
      this.start,
      this.end,
      this.includeCount,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = ['v2', 'objects', keyset.subscribeKey, 'uuids'];
    var queryParameters = {
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter!.isNotEmpty) 'filter': filter,
      if (sort != null && sort!.isNotEmpty) 'sort': sort!.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}'
    };
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Represents UUID metadata.
///
/// {@category Results}
/// {@category Objects}
class UuidMetadataDetails {
  final String _id;
  final String? _name;
  final String? _externalId;
  final String? _profileUrl;
  final String? _email;
  final Map<String, dynamic>? _custom;
  final String? _updated;
  final String? _eTag;

  String get id => _id;
  String? get name => _name;
  String? get externalId => _externalId;
  String? get profileUrl => _profileUrl;
  String? get email => _email;
  dynamic? get custom => _custom;
  String? get updated => _updated;
  String? get eTag => _eTag;

  UuidMetadataDetails._(this._id, this._name, this._externalId, this._email,
      this._profileUrl, this._custom, this._updated, this._eTag);

  factory UuidMetadataDetails.fromJson(dynamic json) => UuidMetadataDetails._(
      json['id'] as String,
      json['name'] as String?,
      json['externalId'] as String?,
      json['email'] as String?,
      json['profileUrl'] as String?,
      json['custom'] as Map<String, dynamic>?,
      json['updated'] as String?,
      json['eTag'] as String?);
}

/// Result of get all UUID metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class GetAllUuidMetadataResult extends Result {
  final List<UuidMetadataDetails>? _metadataList;
  final int? _totalCount;
  final String? _next;
  final String? _prev;

  /// List of UUIDs.
  List<UuidMetadataDetails>? get metadataList => _metadataList;

  /// Total count of UUIDs.
  int? get totalCount => _totalCount;

  String? get next => _next;
  String? get prev => _prev;

  GetAllUuidMetadataResult._(
      this._metadataList, this._totalCount, this._next, this._prev);

  factory GetAllUuidMetadataResult.fromJson(dynamic object) =>
      GetAllUuidMetadataResult._(
          (object['data'] as List)
              .map((e) => UuidMetadataDetails.fromJson(e))
              .toList(),
          object['totalCount'] as int?,
          object['next'] as String?,
          object['prev'] as String?);
}

class GetUuidMetadataParams extends Parameters {
  Keyset keyset;

  String? uuid;
  Set<String>? include;

  GetUuidMetadataParams(this.keyset, {this.include, this.uuid});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'uuids',
      uuid ?? '${keyset.uuid}'
    ];
    var queryParameters = {
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}'
    };
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of get UUID metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class GetUuidMetadataResult extends Result {
  final UuidMetadataDetails? _metadata;

  /// UUID metadata.
  UuidMetadataDetails? get metadata => _metadata;

  GetUuidMetadataResult._(this._metadata);

  factory GetUuidMetadataResult.fromJson(dynamic object) =>
      GetUuidMetadataResult._(UuidMetadataDetails.fromJson(object['data']));
}

class SetUuidMetadataParams extends Parameters {
  Keyset keyset;

  String? uuid;
  Set<String>? include;
  String uuidMetadata;

  SetUuidMetadataParams(this.keyset, this.uuidMetadata,
      {this.include, this.uuid});
  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'uuids',
      uuid ?? '${keyset.uuid}'
    ];
    var queryParameters = {
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey
    };
    return Request.patch(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        body: uuidMetadata);
  }
}

/// Result of set UUID metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class SetUuidMetadataResult extends Result {
  final UuidMetadataDetails _metadata;

  SetUuidMetadataResult._(this._metadata);

  /// UUID metadata.
  UuidMetadataDetails get metadata => _metadata;

  factory SetUuidMetadataResult.fromJson(dynamic object) =>
      SetUuidMetadataResult._(UuidMetadataDetails.fromJson(object['data']));
}

class RemoveUuidMetadataParams extends Parameters {
  Keyset keyset;
  String? uuid;

  RemoveUuidMetadataParams(this.keyset, {this.uuid});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'uuids',
      uuid ?? '${keyset.uuid}'
    ];
    var queryParameters = {if (keyset.authKey != null) 'auth': keyset.authKey};
    return Request.delete(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of remove UUID metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class RemoveUuidMetadataResult extends Result {
  RemoveUuidMetadataResult._();

  factory RemoveUuidMetadataResult.fromJson(dynamic object) =>
      RemoveUuidMetadataResult._();
}
