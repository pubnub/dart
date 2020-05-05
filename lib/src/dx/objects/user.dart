import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/default.dart';

import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/_endpoints/objects/membership.dart';
import 'package:pubnub/src/dx/_endpoints/objects/user.dart';
import 'schema.dart';

final _logger = injectLogger('dx.objects.user');

class UserDx {
  final Core _core;
  UserDx(this._core);

  /// Creates a user with specified deatils [UserDetails]
  /// Returns created object optionally including the user's custom data object
  ///
  /// The custom object can only contain scalar values.
  /// Id and name are required in [user] object.
  /// Returns 400 if required properties are missing, or if any properties are of the wrong type.
  /// Returns 409 if a user already exists with the specified ID.
  Future<CreateUserResult> create(UserDetails user,
      {List<String> include, Keyset keyset, String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(user).isNotNull('user details');
    var payload = await _core.parser.encode(user);
    var params = CreateUserParams(payload, keyset, include: include);

    return defaultFlow<CreateUserParams, CreateUserResult>(
        logger: _logger,
        core: _core,
        params: params,
        serialize: (object, [_]) => CreateUserResult.fromJson(object));
  }

  /// Returns a paginated list of users associated with the given subscription key,
  /// optionally including each user record's custom data object.
  ///
  /// Provide [include] for List of additional/complex user properties to include in response.
  /// Omit this parameter if you don't want to retrieve additional properties.
  ///
  /// You can limit number of returned user object using [limit] parameter
  /// Default is 100, which is also the maximum value.
  ///
  /// You can specify [start] and [end] to specify previously-returned cursor bookmark
  /// for fetching the next/previous page
  ///
  /// [filter] is Expression used to filter the results.
  /// Only objects whose properties satisfy the given expression are returned.
  ///
  /// For sorting, use [sort] which is List of attributes to sort by.
  /// Append :asc or :desc to an attribute to specify sort direction.
  /// The default sort direction is ascending.
  Future<GetAllUsersResult> getAllUsers(
      {List<String> include,
      int limit,
      String start,
      String end,
      bool count,
      String filter,
      List<String> sort,
      Keyset keyset,
      String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');

    var params = GetAllUsersParams(keyset,
        include: include,
        limit: limit,
        start: start,
        end: end,
        count: count,
        filter: filter,
        sort: sort);

    return defaultFlow<GetAllUsersParams, GetAllUsersResult>(
        logger: _logger,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetAllUsersResult.fromJson(object));
  }

  /// Returns the specified user object, optionally including the user's custom data object.
  /// [userId] is unique user identifier to fetch the user object
  Future<GetUserResult> getUser(String userId,
      {Keyset keyset, String using, List<String> include}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(userId).isNotEmpty('userId');
    var params = GetUserParams(keyset, userId, include: include);
    return defaultFlow<GetUserParams, GetUserResult>(
        logger: _logger,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetUserResult.fromJson(object));
  }

  /// Updates the specified [userId] user object with any new information you provide.
  /// Returns the updated user object, optionally including the user's custom data object.
  ///
  /// Notes:
  ///  You can change all of the user object's properties, except its ID.
  ///  Invalid property names are silently ignored and will not cause a request to fail.
  ///  If you update the "custom" property, you must completely replace it; partial updates are not supported.
  ///  The custom object can only contain scalar values.
  Future<UpdateUserResult> updateUser(UserDetails user, String userId,
      {Keyset keyset, String using, List<String> include}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(user).isNotNull('user update details');
    Ensure(userId).isNotEmpty('userId');

    var payload = await _core.parser.encode(user);

    var params = UpdateUserParams(keyset, payload, userId, include: include);

    return defaultFlow<UpdateUserParams, UpdateUserResult>(
        logger: _logger,
        core: _core,
        params: params,
        serialize: (object, [_]) => UpdateUserResult.fromJson(object));
  }

  /// Deletes the specified [userId] user.
  Future<DeleteUserResult> deleteUser(String userId,
      {Keyset keyset, String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(userId).isNotEmpty('userId');

    var params = DeleteUserParams(keyset, userId);

    return defaultFlow<DeleteUserParams, DeleteUserResult>(
        logger: _logger,
        core: _core,
        params: params,
        serialize: (object, [_]) => DeleteUserResult.fromJson(object));
  }
}

/// Representation of a user object
class User {
  final PubNub _core;
  final Keyset _keyset;
  final String _id;

  User(this._core, this._keyset, this._id);

  /// Adds user to space
  /// It registers the user to the spaces [spaceIds]
  /// Provide valid [spaceIds] of spaces to which user needs to be added
  ///
  /// Returns true if user is added to space successfully
  Future<bool> addToSpaces(Set<String> spaceIds) async {
    var success = false;
    var result = await _core.memberships
        .manageUserMemberships(_id, add: spaceIds, keyset: _keyset);
    success = result.status == 200;
    return success;
  }

  /// It returns user's membership list
  ///
  /// Provide [include] List of additional/complex attributes to include in response.
  /// Omit this parameter if you don't want to retrieve additional attributes.
  ///
  /// Use [limit] to specify Number of objects to return in response.
  /// Default is 100, which is also the maximum value.
  ///
  /// [filter] is a Expression used to filter the results.
  /// Only objects whose properties satisfy the given expression are returned.
  ///
  /// Provide [start] and [end] for Previously-returned cursor bookmark for
  /// fetching the next/previous page.
  ///
  /// You can specify [count] to Request totalCount to be included in paginated response.
  /// By default, totalCount is omitted.
  ///
  /// You can provide [sort] List of attributes to sort by.
  /// Append :asc or :desc to an attribute to specify sort direction.
  /// The default sort direction is ascending.
  Future<MembershipsResult> getMemberships(
      {Set<String> include,
      int limit,
      String start,
      String end,
      bool count,
      String filter,
      Set<String> sort,
      Keyset keyset,
      String using}) async {
    return await _core.memberships.getUserMemberships(_id,
        include: include,
        limit: limit,
        start: start,
        end: end,
        count: count,
        filter: filter,
        sort: sort,
        keyset: keyset,
        using: using);
  }
}
