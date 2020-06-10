import 'package:pubnub/src/core/core.dart';

import 'package:pubnub/src/dx/_endpoints/objects/channel_metadata.dart'
    show ChannelMetadataDetails;
import 'package:pubnub/src/dx/_endpoints/objects/uuid_metadata.dart'
    show UuidMetadataDetails;

class GetMembershipsMetadataParams extends Parameters {
  Keyset keyset;
  String uuid;
  int limit;
  String start;
  String end;
  Set<String> include;
  bool includeCount;
  String filter;
  Set<String> sort;

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
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter.isNotEmpty) 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(',')
    };

    return Request(RequestType.get, pathSegments,
        queryParameters: queryParameters);
  }
}

class MembershipMetadata {
  ChannelMetadataDetails _channel;
  dynamic _custom;
  String _updated;
  String _eTag;

  ChannelMetadataDetails get channel => _channel;
  dynamic get custom => _custom;
  String get updated => _updated;
  String get eTag => _eTag;

  MembershipMetadata._();

  factory MembershipMetadata.fromJson(dynamic object) => MembershipMetadata._()
    .._channel = ChannelMetadataDetails.fromJson(object['channel'])
    .._custom = object['custom']
    .._updated = object['updated'] as String
    .._eTag = object['eTag'] as String;
}

class MembershipsResult extends Result {
  List<MembershipMetadata> _metadataList;
  int _totalCount;
  String _next;
  String _prev;

  List<MembershipMetadata> get metadataList => _metadataList;
  int get totalCount => _totalCount;
  String get next => _next;
  String get prev => _prev;

  MembershipsResult._();

  factory MembershipsResult.fromJson(dynamic object) => MembershipsResult._()
    .._metadataList = (object['data'] as List)
        ?.map((e) => e == null ? null : MembershipMetadata.fromJson(e))
        ?.toList()
    .._totalCount = object['totalCount'] as int
    .._next = object['next'] as String
    .._prev = object['prev'] as String;
}

class ManageMembershipsParams extends Parameters {
  Keyset keyset;
  String uuid;
  int limit;
  String start;
  String end;
  Set<String> include;
  bool includeCount;
  String filter;
  Set<String> sort;

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
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter.isNotEmpty) 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(',')
    };

    return Request(RequestType.patch, pathSegments,
        queryParameters: queryParameters, body: membershipMetadata);
  }
}

class GetChannelMembersParams extends Parameters {
  Keyset keyset;
  String channelId;

  int limit;
  String start;
  String end;
  Set<String> include;
  bool includeCount;
  String filter;
  Set<String> sort;

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
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter != '') 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(',')
    };

    return Request(
      RequestType.get,
      pathSegments,
      queryParameters: queryParameters,
    );
  }
}

class ChannelMemberMetadata {
  UuidMetadataDetails _uuid;
  dynamic _custom;
  String _updated;
  String _eTag;

  UuidMetadataDetails get uuid => _uuid;
  dynamic get custom => _custom;
  String get updated => _updated;
  String get eTag => _eTag;

  ChannelMemberMetadata._();

  factory ChannelMemberMetadata.fromJson(dynamic object) =>
      ChannelMemberMetadata._()
        .._uuid = UuidMetadataDetails.fromJson(object['uuid'])
        .._custom = object['custom']
        .._updated = object['updated'] as String
        .._eTag = object['eTag'] as String;
}

class ChannelMembersResult extends Result {
  List<ChannelMemberMetadata> _metadataList;
  int _totalCount;
  String _next;
  String _prev;

  List<ChannelMemberMetadata> get metadataList => _metadataList;
  int get totalCount => _totalCount;
  String get next => _next;
  String get prev => _prev;

  ChannelMembersResult._();

  factory ChannelMembersResult.fromJson(dynamic object) =>
      ChannelMembersResult._()
        .._metadataList = (object['data'] as List)
            ?.map((e) => e == null ? null : ChannelMemberMetadata.fromJson(e))
            ?.toList()
        .._totalCount = object['totalCount'] as int
        .._next = object['next'] as String
        .._prev = object['prev'] as String;
}

class ManageChannelMembersParams extends Parameters {
  Keyset keyset;
  String channelId;

  int limit;
  String start;
  String end;
  Set<String> include;
  bool includeCount;
  String filter;
  Set<String> sort;

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
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': '$limit',
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': '${keyset.authKey}',
      if (includeCount != null) 'count': '$includeCount',
      if (filter != null && filter.isNotEmpty) 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(',')
    };
    return Request(
      RequestType.patch,
      pathSegments,
      queryParameters: queryParameters,
      body: membersMetadata,
    );
  }
}
