import 'package:pubnub/core.dart';

import 'package:pubnub/src/dx/_endpoints/objects/channel_metadata.dart'
    show ChannelMetadataDetails;
import 'package:pubnub/src/dx/_endpoints/objects/uuid_metadata.dart'
    show UuidMetadataDetails;

class GetMembershipsMetadataParams extends Parameters {
  Keyset keyset;
  String? uuid;
  int? limit;
  String? start;
  String? end;
  Set<String>? include;
  bool? includeCount;
  String? filter;
  Set<String>? sort;

  GetMembershipsMetadataParams(this.keyset,
      {this.uuid,
      this.limit,
      this.start,
      this.end,
      this.include,
      this.includeCount,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'uuids',
      uuid ?? '${keyset.uuid}',
      'channels'
    ];

    var queryParameters = {
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter!.isNotEmpty) 'filter': filter,
      if (sort != null && sort!.isNotEmpty) 'sort': sort!.join(',')
    };

    return Request.get(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

/// Represents membership metadata.
///
/// {@category Results}
/// {@category Objects}
class MembershipMetadata {
  ChannelMetadataDetails _channel;
  dynamic? _custom;
  String _updated;
  String _eTag;

  ChannelMetadataDetails get channel => _channel;
  dynamic get custom => _custom;
  String get updated => _updated;
  String get eTag => _eTag;

  MembershipMetadata._(this._channel, this._custom, this._updated, this._eTag);

  factory MembershipMetadata.fromJson(dynamic object) => MembershipMetadata._(
      ChannelMetadataDetails.fromJson(object['channel']),
      object['custom'],
      object['updated'] as String,
      object['eTag'] as String);
}

/// Result of memberships endpoint calls.
///
/// {@category Results}
/// {@category Objects}
class MembershipsResult extends Result {
  final List<MembershipMetadata>? _metadataList;
  final int? _totalCount;
  final String? _next;
  final String? _prev;

  List<MembershipMetadata>? get metadataList => _metadataList;
  int? get totalCount => _totalCount;
  String? get next => _next;
  String? get prev => _prev;

  MembershipsResult._(
      this._metadataList, this._totalCount, this._next, this._prev);

  factory MembershipsResult.fromJson(dynamic object) => MembershipsResult._(
      (object['data'] as List)
          .map((e) => MembershipMetadata.fromJson(e))
          .toList(),
      object['totalCount'] as int?,
      object['next'] as String?,
      object['prev'] as String?);
}

class ManageMembershipsParams extends Parameters {
  Keyset keyset;
  String? uuid;
  int? limit;
  String? start;
  String? end;
  Set<String>? include;
  bool? includeCount;
  String? filter;
  Set<String>? sort;

  String membershipMetadata;

  ManageMembershipsParams(this.keyset, this.membershipMetadata,
      {this.uuid,
      this.limit,
      this.start,
      this.end,
      this.include,
      this.includeCount,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'uuids',
      uuid ?? '${keyset.uuid}',
      'channels'
    ];

    var queryParameters = {
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter!.isNotEmpty) 'filter': filter,
      if (sort != null && sort!.isNotEmpty) 'sort': sort!.join(',')
    };

    return Request.patch(
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        body: membershipMetadata);
  }
}

class GetChannelMembersParams extends Parameters {
  Keyset keyset;
  String channelId;

  int? limit;
  String? start;
  String? end;
  Set<String>? include;
  bool? includeCount;
  String? filter;
  Set<String>? sort;

  GetChannelMembersParams(this.keyset, this.channelId,
      {this.limit,
      this.start,
      this.end,
      this.include,
      this.includeCount,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'channels',
      channelId,
      'uuids',
    ];

    var queryParameters = {
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter != '') 'filter': filter,
      if (sort != null && sort!.isNotEmpty) 'sort': sort!.join(',')
    };

    return Request.get(
        uri: Uri(
      pathSegments: pathSegments,
      queryParameters: queryParameters,
    ));
  }
}

/// Represents channel member metadata.
///
/// {@category Results}
/// {@category Objects}
class ChannelMemberMetadata {
  final UuidMetadataDetails _uuid;
  final dynamic? _custom;
  final String _updated;
  final String _eTag;

  UuidMetadataDetails get uuid => _uuid;
  dynamic? get custom => _custom;
  String get updated => _updated;
  String get eTag => _eTag;

  ChannelMemberMetadata._(this._uuid, this._custom, this._eTag, this._updated);

  factory ChannelMemberMetadata.fromJson(dynamic object) =>
      ChannelMemberMetadata._(
          UuidMetadataDetails.fromJson(object['uuid']),
          object['custom'],
          object['updated'] as String,
          object['eTag'] as String);
}

/// Result of channel members endpoint calls.
///
/// {@category Results}
/// {@category Objects}
class ChannelMembersResult extends Result {
  final List<ChannelMemberMetadata>? _metadataList;
  final int? _totalCount;
  final String? _next;
  final String? _prev;

  List<ChannelMemberMetadata>? get metadataList => _metadataList;
  int? get totalCount => _totalCount;
  String? get next => _next;
  String? get prev => _prev;

  ChannelMembersResult._(
      this._metadataList, this._totalCount, this._next, this._prev);

  factory ChannelMembersResult.fromJson(dynamic object) =>
      ChannelMembersResult._(
          (object['data'] as List)
              .map((e) => ChannelMemberMetadata.fromJson(e))
              .toList(),
          object['totalCount'] as int?,
          object['next'] as String?,
          object['prev'] as String?);
}

class ManageChannelMembersParams extends Parameters {
  Keyset keyset;
  String channelId;

  int? limit;
  String? start;
  String? end;
  Set<String>? include;
  bool? includeCount;
  String? filter;
  Set<String>? sort;

  String membersMetadata;

  ManageChannelMembersParams(this.keyset, this.channelId, this.membersMetadata,
      {this.limit,
      this.start,
      this.end,
      this.include,
      this.includeCount,
      this.filter,
      this.sort});
  @override
  Request toRequest() {
    var pathSegments = [
      'v2',
      'objects',
      keyset.subscribeKey,
      'channels',
      channelId,
      'uuids'
    ];

    var queryParameters = {
      if (include != null && include!.isNotEmpty) 'include': include!.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter!.isNotEmpty) 'filter': filter,
      if (sort != null && sort!.isNotEmpty) 'sort': sort!.join(',')
    };
    return Request.patch(
      uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
      body: membersMetadata,
    );
  }
}
