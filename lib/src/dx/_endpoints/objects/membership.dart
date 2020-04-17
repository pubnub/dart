import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'space.dart';
import 'user.dart';

class GetMembershipsParams extends Parameters {
  Keyset keyset;
  String userId;

  Set<String> include;
  int limit;
  String start;
  String end;
  bool count;
  String filter;
  Set<String> sort;

  GetMembershipsParams(this.keyset, this.userId,
      {this.include,
      this.limit,
      this.start,
      this.end,
      this.count,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'users',
      userId,
      'spaces'
    ];

    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': limit.toString(),
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (count != null) 'count': count.toString(),
      if (filter != null && filter != '') 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(',')
    };

    return Request(RequestType.get, pathSegments,
        queryParameters: queryParameters);
  }
}

class MembershipsResult extends Result {
  int _status;
  List<MembershipInfo> _data;
  int _totalCount;
  String _next;
  String _prev;
  Map<String, dynamic> _error;

  int get status => _status;
  List<MembershipInfo> get data => _data ?? <MembershipInfo>[];
  int get totalCount => _totalCount;
  String get next => _next;
  String get prev => _prev;
  Map<String, dynamic> get error => _error;

  MembershipsResult();

  factory MembershipsResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return MembershipsResult()
      .._status = result.status as int
      .._data = (result.data as List)
          ?.map((e) => e == null ? null : MembershipInfo.fromJson(e))
          ?.toList()
      .._error = result.error
      .._totalCount = result.otherKeys['totalCount'] as int
      .._next = result.otherKeys['next'] as String
      .._prev = result.otherKeys['prev'] as String;
  }
}

class MembershipInfo {
  String _id;
  dynamic _custom;
  SpaceInfo _space;
  String _created;
  String _updated;
  String _eTag;

  String get id => _id;
  SpaceInfo get space => _space;
  dynamic get custom => _custom;
  String get created => _created;
  String get updated => _updated;
  String get eTag => _eTag;

  MembershipInfo();

  factory MembershipInfo.fromJson(dynamic object) {
    return MembershipInfo()
      .._id = object['id'] as String
      .._custom = object['custom']
      .._space =
          object['space'] == null ? null : SpaceInfo.fromJson(object['space'])
      .._created = object['created'] as String
      .._updated = object['updated'] as String
      .._eTag = object['eTag'] as String;
  }
}

class ManageMembershipsParams extends Parameters {
  Keyset keyset;
  String userId;

  Set<String> include;
  int limit;
  String start;
  String end;
  bool count;
  String filter;
  Set<String> sort;

  String membershipChanges; // Json String

  ManageMembershipsParams(this.keyset, this.userId, this.membershipChanges,
      {this.include,
      this.limit,
      this.start,
      this.end,
      this.count,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'users',
      userId,
      'spaces'
    ];

    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': limit.toString(),
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (count != null) 'count': count.toString(),
      if (filter != null && filter != '') 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(',')
    };

    return Request(
      RequestType.patch,
      pathSegments,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      body: membershipChanges,
    );
  }
}

class GetSpaceMembersParams extends Parameters {
  Keyset keyset;
  String spaceId;

  Set<String> include;
  int limit;
  String start;
  String end;
  bool count;
  String filter;
  Set<String> sort;

  GetSpaceMembersParams(this.keyset, this.spaceId,
      {this.include,
      this.limit,
      this.start,
      this.end,
      this.count,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'spaces',
      spaceId,
      'users',
    ];
    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': limit.toString(),
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (count != null) 'count': count.toString(),
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

class SpaceMembersResult extends Result {
  int _status;
  List<SpaceMemberInfo> _data;
  int _totalCount;
  String _next;
  String _prev;
  Map<String, dynamic> _error;

  int get status => _status;
  List<SpaceMemberInfo> get data => _data ?? <SpaceMemberInfo>[];
  int get totalCount => _totalCount;
  String get next => _next;
  String get prev => _prev;
  Map<String, dynamic> get error => _error;

  SpaceMembersResult();

  factory SpaceMembersResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return SpaceMembersResult()
      .._status = result.status as int
      .._data = (result.data as List)
          ?.map((e) => e == null ? null : SpaceMemberInfo.fromJson(e))
          ?.toList()
      .._error = result.error
      .._totalCount = result.otherKeys['totalCount'] as int
      .._next = result.otherKeys['next'] as String
      .._prev = result.otherKeys['prev'] as String;
  }
}

class SpaceMemberInfo {
  String _id;
  dynamic _custom;
  UserInfo _user;
  String _created;
  String _updated;
  String _eTag;

  String get id => _id;
  dynamic get custom => _custom;
  UserInfo get user => _user;
  String get created => _created;
  String get updated => _updated;
  String get eTag => _eTag;

  SpaceMemberInfo();

  factory SpaceMemberInfo.fromJson(dynamic object) {
    return SpaceMemberInfo()
      .._id = object['id'] as String
      .._custom = object['custom']
      .._user =
          object['user'] == null ? null : UserInfo.fromJson(object['user'])
      .._created = object['created'] as String
      .._updated = object['updated'] as String
      .._eTag = object['eTag'] as String;
  }
}

class ManageSpaceMembersParams extends Parameters {
  Keyset keyset;
  String spaceId;

  Set<String> include;
  int limit;
  String start;
  String end;
  bool count;
  String filter;
  Set<String> sort;

  String spaceMembersChanges; // Json String

  ManageSpaceMembersParams(this.keyset, this.spaceId, this.spaceMembersChanges,
      {this.include,
      this.limit,
      this.start,
      this.end,
      this.count,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'spaces',
      spaceId,
      'users'
    ];

    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (limit != null) 'limit': limit.toString(),
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (count != null) 'count': count.toString(),
      if (filter != null && filter != '') 'filter': filter,
      if (sort != null && sort.isNotEmpty) 'sort': sort.join(',')
    };

    return Request(
      RequestType.patch,
      pathSegments,
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      body: spaceMembersChanges,
    );
  }
}
