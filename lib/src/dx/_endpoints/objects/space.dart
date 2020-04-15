import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

class CreateSpaceParams extends Parameters {
  Keyset keyset;
  List<String> include;
  String space;

  CreateSpaceParams(this.space, this.keyset, {this.include});

  Request toRequest() {
    List<String> pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'spaces'
    ];

    Map<String, String> queryParameters = {
      if (include != null && include.length > 0)
        'include': this.include.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request(
        type: RequestType.post,
        uri: Uri(
            pathSegments: pathSegments,
            queryParameters:
                queryParameters.length > 0 ? queryParameters : null),
        headers: {'Content-Type': 'application/json'},
        body: space);
  }
}

class UpdateSpaceParams extends Parameters {
  Keyset keyset;
  List<String> include;
  String space;
  String spaceId;

  UpdateSpaceParams(this.keyset, this.space, this.spaceId, {this.include});

  Request toRequest() {
    List<String> pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'spaces',
      spaceId
    ];

    Map<String, String> queryParameters = {
      if (include != null && include.length > 0)
        'include': this.include.join(','),
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request(
        type: RequestType.patch,
        uri: Uri(
            pathSegments: pathSegments,
            queryParameters:
                queryParameters.length > 0 ? queryParameters : null),
        body: space,
        headers: {'Content-Type': 'application/json'});
  }
}

class DeleteSpaceParams extends Parameters {
  Keyset keyset;
  String spaceId;

  DeleteSpaceParams(this.keyset, this.spaceId);

  Request toRequest() {
    List<String> pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'spaces',
      spaceId
    ];

    Map<String, String> queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
    };

    return Request(
        type: RequestType.delete,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters));
  }
}

class GetSpaceParams extends Parameters {
  Keyset keyset;
  String spaceId;

  List<String> include;

  GetSpaceParams(this.keyset, this.spaceId, {this.include});

  Request toRequest() {
    Map<String, String> queryParameters = {
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (include != null && include.length > 0) 'include': include.join(','),
    };

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: [
          'v1',
          'objects',
          keyset.subscribeKey,
          'spaces',
          spaceId,
        ], queryParameters: queryParameters),
        headers: {'Content-Type': 'application/json'});
  }
}

class GetAllSpacesParams extends Parameters {
  Keyset keyset;
  List<String> include;
  int limit;
  String start;
  String end;
  bool count;
  String filter;
  List<String> sort;

  GetAllSpacesParams(this.keyset,
      {this.include,
      this.limit,
      this.start,
      this.end,
      this.count,
      this.filter,
      this.sort});

  Request toRequest() {
    List<String> pathSegments = [
      'v1',
      'objects',
      keyset.subscribeKey,
      'spaces'
    ];

    Map<String, String> queryParameters = {
      if (include != null && include.length > 0) 'include': include.join(','),
      if (limit != null) 'limit': limit.toString(),
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (keyset.authKey != null) 'auth': keyset.authKey,
      if (count != null) 'count': count.toString(),
      if (filter != null && filter != '') 'filter': filter,
      if (sort != null && sort.length > 0) 'sort': sort.join(',')
    };

    return Request(
        type: RequestType.get,
        uri: Uri(pathSegments: pathSegments, queryParameters: queryParameters),
        headers: {'Content-Type': 'application/json'});
  }
}

class SpaceInfo {
  String _id;
  String _name;
  String _description;
  dynamic _custom;
  String _created;
  String _updated;
  String _eTag;

  String get id => _id;
  String get name => _name;
  String get description => _description;
  dynamic get custom => _custom;
  String get created => _created;
  String get updated => _updated;
  String get eTag => _eTag;

  SpaceInfo();

  factory SpaceInfo.fromJson(dynamic object) {
    return SpaceInfo()
      .._id = object['id'] as String
      .._name = object['name'] as String
      .._description = object['description'] as String
      .._custom = object['custom']
      .._created = object['created'] as String
      .._updated = object['updated'] as String
      .._eTag = object['eTag'] as String;
  }
}

class GetSpaceResult extends Result {
  int _status;
  SpaceInfo _data;
  Map<String, dynamic> _error;

  int get status => _status;
  SpaceInfo get data => _data ?? SpaceInfo();
  Map<String, dynamic> get error => _error;

  GetSpaceResult();

  factory GetSpaceResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return GetSpaceResult()
      .._status = result.status as int
      .._error = result.error
      .._data = result.error.length == 0 ? SpaceInfo.fromJson(result.data) : {};
  }
}

class GetAllSpacesResult extends Result {
  int _status;
  List<SpaceInfo> _data;
  int _totalCount;
  String _next;
  String _prev;
  Map<String, dynamic> _error;

  int get status => _status;
  List<SpaceInfo> get data => _data ?? List<SpaceInfo>();
  int get totalCount => _totalCount;
  String get next => _next;
  String get prev => _prev;
  Map<String, dynamic> get error => _error;

  GetAllSpacesResult();

  factory GetAllSpacesResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);

    return GetAllSpacesResult()
      .._status = result.status as int
      .._error = result.error
      .._data = (result.data as List)
          ?.map((e) => e == null ? null : SpaceInfo.fromJson(e))
          ?.toList()
      .._totalCount = result.otherKeys['totalCount'] as int
      .._next = result.otherKeys['next'] as String
      .._prev = result.otherKeys['prev'] as String;
  }
}

class UpdateSpaceResult extends Result {
  int _status;
  SpaceInfo _data;
  Map<String, dynamic> _error;

  UpdateSpaceResult();

  int get status => _status;
  SpaceInfo get data => _data ?? SpaceInfo();
  Map<String, dynamic> get error => _error;

  factory UpdateSpaceResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return UpdateSpaceResult()
      .._status = result.status as int
      .._error = result.error
      .._data = result.data != null ? SpaceInfo.fromJson(result.data) : null;
  }
}

class DeleteSpaceResult extends Result {
  String _status;
  dynamic _data;
  Map<String, dynamic> _error;

  String get status => _status;
  dynamic get data => _data;
  Map<String, dynamic> get error => _error;

  DeleteSpaceResult();

  factory DeleteSpaceResult.fromJson(dynamic object) {
    var result = DefaultObjectResult.fromJson(object);
    return DeleteSpaceResult()
      .._status = result.status as String
      .._error = result.error
      .._data = result.error.length == 0 ? result.data : {};
  }
}

class CreateSpaceResult extends Result {
  int _status;
  SpaceInfo _data;
  Map<String, dynamic> _error;

  int get status => _status;
  SpaceInfo get data => _data ?? SpaceInfo();
  Map<String, dynamic> get error => _error;

  CreateSpaceResult();

  factory CreateSpaceResult.fromJson(Map<String, dynamic> object) {
    var result = DefaultObjectResult.fromJson(object);
    return CreateSpaceResult()
      .._status = result.status as int
      .._error = result.error
      .._data =
          result.error.length == 0 ? SpaceInfo.fromJson(result.data) : null;
  }
}
