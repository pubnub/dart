import 'package:pubnub/src/core/core.dart';

class GetAllChannelMetadataParams extends Parameters {
  Keyset keyset;
  Set<String> include;
  int limit;
  String start;
  String end;
  bool includeCount;
  String filter;
  Set<String> sort;

  GetAllChannelMetadataParams(this.keyset,
      {this.limit,
      this.include,
      this.start,
      this.end,
      this.includeCount,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = ['v2', 'objects', keyset.subscribeKey, 'channels'];

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

class ChannelMetadataDetails {
  String _id;
  String _name;
  String _description;
  Map<String, dynamic> _custom;
  String _updated;
  String _eTag;

  String get id => _id;
  String get name => _name;
  String get description => _description;
  Map<String, dynamic> get custom => _custom;
  String get updated => _updated;
  String get eTag => _eTag;

  ChannelMetadataDetails._();

  factory ChannelMetadataDetails.fromJson(dynamic object) =>
      ChannelMetadataDetails._()
        .._id = object['id'] as String
        .._name = object['name'] as String
        .._description = object['description'] as String
        .._custom = object['custom'] as Map<String, dynamic>
        .._updated = object['updated'] as String
        .._eTag = object['eTag'] as String;
}

class GetAllChannelMetadataResult extends Result {
  List<ChannelMetadataDetails> _metadataList;
  int _totalCount;
  String _next;
  String _prev;

  List<ChannelMetadataDetails> get metadataList => _metadataList;
  int get totalCount => _totalCount;
  String get next => _next;
  String get prev => _prev;

  GetAllChannelMetadataResult();

  factory GetAllChannelMetadataResult.fromJson(dynamic object) =>
      GetAllChannelMetadataResult()
        .._metadataList = (object['data'] as List)
            ?.map((e) => e == null ? null : ChannelMetadataDetails.fromJson(e))
            ?.toList()
        .._totalCount = object['totalCount'] as int
        .._next = object['next'] as String
        .._prev = object['prev'] as String;
}

class GetChannelMetadataParams extends Parameters {
  Keyset keyset;
  String channelId;

  Set<String> include;

  GetChannelMetadataParams(this.keyset, this.channelId, {this.include});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'channels',
      channelId,
    ];
    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class GetChannelMetadataResult extends Result {
  ChannelMetadataDetails _metadata;
  ChannelMetadataDetails get metadata => _metadata;

  GetChannelMetadataResult._();

  factory GetChannelMetadataResult.fromJson(dynamic object) =>
      GetChannelMetadataResult._()
        .._metadata = ChannelMetadataDetails.fromJson(object['data']);
}

class SetChannelMetadataParams extends Parameters {
  Keyset keyset;
  String channelId;

  Set<String> include;

  String channelMetadata;

  SetChannelMetadataParams(this.keyset, this.channelId, this.channelMetadata,
      {this.include});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'channels',
      channelId
    ];

    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request.patch(
        uri: Uri(
            pathSegments: pathSegments,
            queryParameters:
                queryParameters.isNotEmpty ? queryParameters : null),
        body: channelMetadata);
  }
}

class SetChannelMetadataResult extends Result {
  ChannelMetadataDetails _metadata;
  SetChannelMetadataResult._();

  ChannelMetadataDetails get metadata => _metadata;

  factory SetChannelMetadataResult.fromJson(dynamic object) =>
      SetChannelMetadataResult._()
        .._metadata = ChannelMetadataDetails.fromJson(object['data']);
}

class RemoveChannelMetadataParams extends Parameters {
  Keyset keyset;
  String channelID;

  RemoveChannelMetadataParams(this.keyset, this.channelID);

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'channels',
      channelID
    ];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request.delete(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class RemoveChannelMetadataResult extends Result {
  RemoveChannelMetadataResult._();

  factory RemoveChannelMetadataResult.fromJson(dynamic object) =>
      RemoveChannelMetadataResult._();
}
