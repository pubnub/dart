import 'package:pubnub/core.dart';

import '../../datasync/schema.dart';

const _userContentType = 'application/vnd.pubnub.objects.user+json;version=1';
const _patchContentType = 'application/json-patch+json';

List<String> _basePath(Keyset keyset) =>
    ['v1', 'datasync', 'subkeys', keyset.subscribeKey, 'users'];

class CreateUserParams extends Parameters {
  Keyset keyset;
  String user;

  CreateUserParams(this.keyset, this.user);

  Map<String, dynamic> toJson() {
    return {
      'user': user,
    };
  }

  @override
  Request toRequest() {
    return Request.post(
        uri: Uri(pathSegments: _basePath(keyset)),
        body: user,
        headers: {'Content-Type': _userContentType});
  }
}

/// Result of create user endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class CreateUserResult extends Result {
  final UserRecord _user;

  /// Created user.
  UserRecord get user => _user;

  CreateUserResult._(this._user);

  factory CreateUserResult.fromJson(dynamic object) => CreateUserResult._(
      UserRecord.fromJson(object is Map ? object['data'] : null));
}

class GetUsersParams extends Parameters {
  Keyset keyset;
  String? className;
  int? classVersion;
  ClassLevel? classLevel;
  String? cursor;
  int? limit;
  String? filterFast;
  String? filter;
  String? sort;

  GetUsersParams(this.keyset,
      {this.className,
      this.classVersion,
      this.classLevel,
      this.cursor,
      this.limit,
      this.filterFast,
      this.filter,
      this.sort});

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'classVersion': classVersion,
      'classLevel': classLevel?.value,
      'cursor': cursor,
      'limit': limit,
      'filterFast': filterFast,
      'filter': filter,
      'sort': sort,
    };
  }

  @override
  Request toRequest() {
    var queryParameters = {
      if (className != null && className!.isNotEmpty)
        'entity_class': className!,
      if (classVersion != null) 'entity_class_version': '$classVersion',
      if (classLevel != null) 'entity_class_level': classLevel!.value,
      if (cursor != null && cursor!.isNotEmpty) 'cursor': cursor!,
      if (limit != null) 'limit': '$limit',
      if (filterFast != null && filterFast!.isNotEmpty)
        'filter_fast': filterFast!,
      if (filter != null && filter!.isNotEmpty) 'filter': filter!,
      if (sort != null && sort!.isNotEmpty) 'sort': sort!,
    };

    // Every query parameter is optional, and an empty map would render a
    // trailing `?` on the URL, so it is omitted entirely when unused.
    return Request.get(
        uri: Uri(
            pathSegments: _basePath(keyset),
            queryParameters: queryParameters.isEmpty ? null : queryParameters));
  }
}

/// Result of get users endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetUsersResult extends Result {
  final List<UserRecord> _users;
  final DataSyncPage? _page;
  final DataSyncLinks? _links;

  /// Users of the requested page.
  List<UserRecord> get users => _users;

  /// Pagination metadata. It is `null` when the server omits it.
  DataSyncPage? get page => _page;

  /// Opaque cursor of the next page, `null` when there are no more results.
  String? get nextCursor => _page?.nextCursor;

  /// Whether there are more results after this page.
  bool get hasNext => _page?.hasNext ?? false;

  /// Hypermedia links of the listing. It is `null` when the server omits
  /// them.
  DataSyncLinks? get links => _links;

  GetUsersResult._(this._users, this._page, this._links);

  factory GetUsersResult.fromJson(dynamic object) => GetUsersResult._(
      dataSyncRows(object)
          .map<UserRecord>((e) => UserRecord.fromJson(e))
          .toList(),
      object['meta'] != null ? DataSyncPage.fromJson(object['meta']) : null,
      DataSyncLinks.maybeFromJson(object['links']));
}

class GetUserParams extends Parameters {
  Keyset keyset;
  String userId;

  GetUserParams(this.keyset, this.userId);

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
    };
  }

  @override
  Request toRequest() {
    return Request.get(uri: Uri(pathSegments: [..._basePath(keyset), userId]));
  }
}

/// Result of get user endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetUserResult extends Result {
  final UserRecord _user;

  /// Requested user.
  UserRecord get user => _user;

  GetUserResult._(this._user);

  factory GetUserResult.fromJson(dynamic object) => GetUserResult._(
      UserRecord.fromJson(object is Map ? object['data'] : null));
}

class SetUserParams extends Parameters {
  Keyset keyset;
  String userId;
  String user;
  String? ifMatchesEtag;

  SetUserParams(this.keyset, this.userId, this.user, {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'user': user,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.put(
        uri: Uri(pathSegments: [..._basePath(keyset), userId]),
        body: user,
        headers: {
          'Content-Type': _userContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of set user endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class SetUserResult extends Result {
  final UserRecord _user;

  /// User after the replacement.
  UserRecord get user => _user;

  SetUserResult._(this._user);

  factory SetUserResult.fromJson(dynamic object) => SetUserResult._(
      UserRecord.fromJson(object is Map ? object['data'] : null));
}

class UpdateUserParams extends Parameters {
  Keyset keyset;
  String userId;
  String patch;
  String? ifMatchesEtag;

  UpdateUserParams(this.keyset, this.userId, this.patch, {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'patch': patch,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.patch(
        uri: Uri(pathSegments: [..._basePath(keyset), userId]),
        body: patch,
        headers: {
          'Content-Type': _patchContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of update user endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class UpdateUserResult extends Result {
  final UserRecord _user;

  /// User after the patch has been applied.
  UserRecord get user => _user;

  UpdateUserResult._(this._user);

  factory UpdateUserResult.fromJson(dynamic object) => UpdateUserResult._(
      UserRecord.fromJson(object is Map ? object['data'] : null));
}

class RemoveUserParams extends Parameters {
  Keyset keyset;
  String userId;
  String? ifMatchesEtag;

  RemoveUserParams(this.keyset, this.userId, {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.delete(
        uri: Uri(pathSegments: [..._basePath(keyset), userId]),
        headers: {
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of remove user endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class RemoveUserResult extends Result {
  RemoveUserResult._();

  /// @nodoc
  factory RemoveUserResult.empty() => RemoveUserResult._();
}
