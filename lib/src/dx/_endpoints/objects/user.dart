import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class CreateUserParams extends Parameters {
  Keyset keyset;

  List<String> include;

  String user;

  CreateUserParams(this.user, this.keyset, {this.include});

  @override
  Request toRequest() {
    var pathSegments = ['v1', 'objects', keyset.subscribeKey, 'users'];

    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request(RequestType.post, pathSegments,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        headers: {'Content-Type': 'application/json'},
        body: user);
  }
}

class UpdateUserParams extends Parameters {
  Keyset keyset;
  String user;
  String userId;

  List<String> include;

  UpdateUserParams(this.keyset, this.user, this.userId, {this.include});

  @override
  Request toRequest() {
    var pathSegments = ['v1', 'objects', keyset.subscribeKey, 'users', userId];

    var queryParameters = {
      if (include != null && include.isNotEmpty) 'include': include.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request(RequestType.patch, pathSegments,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        headers: {'Content-Type': 'application/json'},
        body: user);
  }
}

class DeleteUserParams extends Parameters {
  Keyset keyset;
  String userId;

  DeleteUserParams(this.keyset, this.userId);

  @override
  Request toRequest() {
    var pathSegments = ['v1', 'objects', keyset.subscribeKey, 'users', userId];

    var queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request(RequestType.delete, pathSegments,
        queryParameters: queryParameters,
        headers: {'Content-Type': 'application/json'});
  }
}

class GetUserParams extends Parameters {
  Keyset keyset;
  String userid;

  List<String> include;

  GetUserParams(this.keyset, this.userid, {this.include});

  @override
  Request toRequest() {
    var pathSegments = ['v1', 'objects', keyset.subscribeKey, 'users', userid];
    var queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (include != null && include.isNotEmpty) 'include': include.join(','),
    };

    return Request(RequestType.get, pathSegments,
        queryParameters: queryParameters);
  }
}

class GetAllUsersParams extends Parameters {
  Keyset keyset;

  List<String> include;
  int limit;
  String start;
  String end;
  bool count;
  String filter;
  List<String> sort;

  GetAllUsersParams(this.keyset,
      {this.include,
      this.limit,
      this.start,
      this.end,
      this.count,
      this.filter,
      this.sort});

  @override
  Request toRequest() {
    var pathSegments = ['v1', 'objects', keyset.subscribeKey, 'users'];

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
        queryParameters: queryParameters,
        headers: {'Content-Type': 'application/json'});
  }
}

class UserInfo {
  String _id;
  String _name;
  String _externalId;
  String _profileUrl;
  String _email;
  dynamic _custom;
  String _created;
  String _updated;
  String _eTag;

  String get id => _id;
  String get name => _name;
  String get externalId => _externalId;
  String get profileUrl => _profileUrl;
  String get email => _email;
  dynamic get custom => _custom;
  String get created => _created;
  String get updated => _updated;
  String get eTag => _eTag;

  UserInfo();

  factory UserInfo.fromJson(dynamic json) {
    return UserInfo()
      .._id = json['id'] as String
      .._name = json['name'] as String
      .._externalId = json['externalId'] as String
      .._profileUrl = json['profileUrl'] as String
      .._email = json['email'] as String
      .._custom = json['custom']
      .._created = json['created'] as String
      .._updated = json['upadted'] as String
      .._eTag = json['eTag'] as String;
  }
}

class UpdateUserResult extends Result {
  int _status;
  UserInfo _data;
  Map<String, dynamic> _error;

  UpdateUserResult();

  int get status => _status;
  UserInfo get data => _data ?? UserInfo();
  Map<String, dynamic> get error => _error;

  factory UpdateUserResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return UpdateUserResult()
      .._status = result.status as int
      .._error = result.error
      .._data = result.data == null ? null : UserInfo.fromJson(result.data);
  }
}

class GetAllUsersResult extends Result {
  int _status;
  List<UserInfo> _data;
  int _totalCount;
  Map<String, dynamic> _error;

  int get status => _status;
  List<UserInfo> get data => _data ?? <UserInfo>[];
  int get totalCount => _totalCount;
  Map<String, dynamic> get error => _error;

  GetAllUsersResult();

  factory GetAllUsersResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);

    return GetAllUsersResult()
      .._status = result.status as int
      .._error = result.error
      .._data = (result.data as List)
          ?.map((e) => e == null ? null : UserInfo.fromJson(e))
          ?.toList()
      .._totalCount = result.otherKeys['totalCount'] as int;
  }
}

class GetUserResult extends Result {
  int _status;
  UserInfo _data;
  Map<String, dynamic> _error;

  int get status => _status;
  UserInfo get data => _data ?? UserInfo();
  Map<String, dynamic> get error => _error;

  GetUserResult();

  factory GetUserResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return GetUserResult()
      .._status = result.status as int
      .._error = result.error
      .._data = result.data == null ? null : UserInfo.fromJson(result.data);
  }
}

class DeleteUserResult extends Result {
  dynamic _status;
  dynamic _data;
  Map<String, dynamic> _error;

  dynamic get status => _status;
  dynamic get data => _data;
  Map<String, dynamic> get error => _error;

  DeleteUserResult();

  factory DeleteUserResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return DeleteUserResult()
      .._status = result.status
      .._error = result.error
      .._data = result.data;
  }
}

class CreateUserResult extends Result {
  int _status;
  UserInfo _data;
  Map<String, dynamic> _error;

  int get status => _status;
  UserInfo get data => _data ?? UserInfo();
  Map<String, dynamic> get error => _error;

  CreateUserResult();

  factory CreateUserResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultObjectResult.fromJson(object);
    return CreateUserResult()
      .._status = result.status as int
      .._error = result.error
      .._data = result.error.isEmpty ? UserInfo.fromJson(result.data) : null;
  }
}
