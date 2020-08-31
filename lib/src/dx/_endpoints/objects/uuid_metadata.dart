import 'package:pubnub/src/core/core.dart';

class GetAllUuidMetadataParams extends Parameters {
  Keyset keyset;
  Set<String> include;
  int limit;
  String start;
  String end;
  bool includeCount;
  String filter;
  Set<String> sort;

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
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter.isNotEmpty) 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}'
    };
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class UuidMetadataDetails {
  String _id;
  String _name;
  String _externalId;
  String _profileUrl;
  String _email;
  Map<String, dynamic> _custom;
  String _updated;
  String _eTag;

  String get id => _id;
  String get name => _name;
  String get externalId => _externalId;
  String get profileUrl => _profileUrl;
  String get email => _email;
  dynamic get custom => _custom;
  String get updated => _updated;
  String get eTag => _eTag;

  UuidMetadataDetails._();

  factory UuidMetadataDetails.fromJson(dynamic json) => UuidMetadataDetails._()
    .._id = json['id'] as String
    .._name = json['name'] as String
    .._externalId = json['externalId'] as String
    .._profileUrl = json['profileUrl'] as String
    .._email = json['email'] as String
    .._custom = json['custom'] as Map<String, dynamic>
    .._updated = json['upadted'] as String
    .._eTag = json['eTag'] as String;
}

class GetAllUuidMetadataResult extends Result {
  List<UuidMetadataDetails> _metadataList;
  int _totalCount;
  String _next;
  String _prev;

  List<UuidMetadataDetails> get metadataList => _metadataList;
  int get totalCount => _totalCount;
  String get next => _next;
  String get prev => _prev;

  GetAllUuidMetadataResult._();

  factory GetAllUuidMetadataResult.fromJson(dynamic object) =>
      GetAllUuidMetadataResult._()
        .._metadataList = (object['data'] as List)
            ?.map((e) => e == null ? null : UuidMetadataDetails.fromJson(e))
            ?.toList()
        .._totalCount = object['totalCount'] as int
        .._next = object['next'] as String
        .._prev = object['prev'] as String;
}

class GetUuidMetadataParams extends Parameters {
  Keyset keyset;
  String uuid;

  Set<String> include;

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
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (keyset.authKey != null) 'auth': '${keyset.authKey}'
    };
    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class GetUuidMetadataResult extends Result {
  UuidMetadataDetails _metadata;

  UuidMetadataDetails get metadata => _metadata;

  GetUuidMetadataResult();

  factory GetUuidMetadataResult.fromJson(dynamic object) =>
      GetUuidMetadataResult()
        .._metadata = UuidMetadataDetails.fromJson(object['data']);
}

class SetUuidMetadataParams extends Parameters {
  Keyset keyset;
  String uuid;

  Set<String> include;

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
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey
    };
    return Request.patch(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        body: uuidMetadata);
  }
}

class SetUuidMetadataResult extends Result {
  UuidMetadataDetails _metadata;

  SetUuidMetadataResult._();

  UuidMetadataDetails get metadata => _metadata;

  factory SetUuidMetadataResult.fromJson(dynamic object) =>
      SetUuidMetadataResult._()
        .._metadata = UuidMetadataDetails.fromJson(object['data']);
}

class RemoveUuidMetadataParams extends Parameters {
  Keyset keyset;
  String uuid;

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

class RemoveUuidMetadataResult extends Result {
  RemoveUuidMetadataResult._();

  factory RemoveUuidMetadataResult.fromJson(dynamic object) =>
      RemoveUuidMetadataResult._();
}
