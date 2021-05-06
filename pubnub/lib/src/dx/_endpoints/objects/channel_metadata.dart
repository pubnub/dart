import 'package:pubnub/core.dart';

class GetAllChannelMetadataParams extends Parameters {
  Keyset keyset;
  Set<String>? include;
  int? limit;
  String? start;
  String? end;
  bool? includeCount;
  String? filter;
  Set<String>? sort;

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

/// Represents channel metadata.
///
/// {@category Results}
/// {@category Objects}
class ChannelMetadataDetails {
  String _id;
  String? _name;
  String? _description;
  Map<String, dynamic>? _custom;
  String? _updated;
  String? _eTag;

  String get id => _id;
  String? get name => _name;
  String? get description => _description;
  Map<String, dynamic>? get custom => _custom;
  String? get updated => _updated;
  String? get eTag => _eTag;

  ChannelMetadataDetails._(this._id, this._name, this._description,
      this._custom, this._updated, this._eTag);

  factory ChannelMetadataDetails.fromJson(dynamic object) =>
      ChannelMetadataDetails._(
          object['id'] as String,
          object['name'] as String?,
          object['description'] as String?,
          object['custom'] as Map<String, dynamic>?,
          object['updated'] as String?,
          object['eTag'] as String?);
}

/// Result of get all channels metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class GetAllChannelMetadataResult extends Result {
  final List<ChannelMetadataDetails>? _metadataList;
  final int? _totalCount;
  final String? _next;
  final String? _prev;

  List<ChannelMetadataDetails>? get metadataList => _metadataList;
  int? get totalCount => _totalCount;
  String? get next => _next;
  String? get prev => _prev;

  GetAllChannelMetadataResult(
      this._metadataList, this._totalCount, this._next, this._prev);

  factory GetAllChannelMetadataResult.fromJson(dynamic object) =>
      GetAllChannelMetadataResult(
          (object['data'] as List)
              .map((e) => ChannelMetadataDetails.fromJson(e))
              .toList(),
          object['totalCount'] as int?,
          object['next'] as String?,
          object['prev'] as String?);
}

class GetChannelMetadataParams extends Parameters {
  Keyset keyset;
  String channelId;

  Set<String>? include;

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
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Result of get channels metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class GetChannelMetadataResult extends Result {
  final ChannelMetadataDetails _metadata;

  ChannelMetadataDetails get metadata => _metadata;

  GetChannelMetadataResult._(this._metadata);

  factory GetChannelMetadataResult.fromJson(dynamic object) =>
      GetChannelMetadataResult._(
          ChannelMetadataDetails.fromJson(object['data']));
}

class SetChannelMetadataParams extends Parameters {
  Keyset keyset;
  String channelId;

  Set<String>? include;

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
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
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

/// Result of set channels metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class SetChannelMetadataResult extends Result {
  final ChannelMetadataDetails _metadata;

  SetChannelMetadataResult._(this._metadata);

  ChannelMetadataDetails get metadata => _metadata;

  factory SetChannelMetadataResult.fromJson(dynamic object) =>
      SetChannelMetadataResult._(
          ChannelMetadataDetails.fromJson(object['data']));
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

/// Result of remove channels metadata endpoint call.
///
/// {@category Results}
/// {@category Objects}
class RemoveChannelMetadataResult extends Result {
  RemoveChannelMetadataResult._();

  factory RemoveChannelMetadataResult.fromJson(dynamic object) =>
      RemoveChannelMetadataResult._();
}
