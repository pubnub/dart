import 'package:logging/logging.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'package:pubnub/src/dx/_endpoints/objects/membership.dart';
import 'package:pubnub/src/dx/_endpoints/objects/space.dart';
import 'schema.dart';

final _log = Logger('pubnub.dx.objects.space');

class SpaceDx {
  final Core _core;
  SpaceDx(this._core);

  /// Creates a space with the specified attributes.
  /// Returns the created space object, optionally including its custom data object.
  ///
  /// Space ID and name are required.
  /// The custom object can only contain scalar values.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [EnsureException].
  ///
  /// Returns 409 if a space already exists with the specified ID
  Future<CreateSpaceResult> create(SpaceDetails space,
      {List<String> include, Keyset keyset, String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(space).isNotNull('space details');
    var payload = await _core.parser.encode(space);
    var params = CreateSpaceParams(payload, keyset, include: include);

    return defaultFlow<CreateSpaceParams, CreateSpaceResult>(
        log: _log,
        core: _core,
        params: params,
        serialize: (object, [_]) => CreateSpaceResult.fromJson(object));
  }

  /// Returns the spaces associated with the given subscriber key,
  /// optionally including each space's custom data object.
  ///
  /// Provide [include] List of additional/complex attributes to include in response.
  /// Omit this parameter if you don't want to retrieve additional attributes.
  ///
  /// Use [limit] to specify Number of objects to return in response.
  /// Default is 100, which is also the maximum value.
  ///
  /// Provide [start] and [end] for Previously-returned cursor bookmark for
  /// fetching the next/previous page.
  ///
  /// You can specify [count] to Request totalCount to be included in paginated response.
  /// By default, totalCount is omitted.
  ///
  /// [filter] is a Expression used to filter the results.
  /// Only objects whose properties satisfy the given expression are returned.
  ///
  /// You can provide [sort] List of attributes to sort by.
  /// Append :asc or :desc to an attribute to specify sort direction.
  /// The default sort direction is ascending.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [EnsureException].
  Future<GetAllSpacesResult> getAllSpaces(
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
    var params = GetAllSpacesParams(keyset,
        include: include,
        limit: limit,
        start: start,
        end: end,
        count: count,
        filter: filter,
        sort: sort);

    return defaultFlow<GetAllSpacesParams, GetAllSpacesResult>(
        log: _log,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetAllSpacesResult.fromJson(object));
  }

  /// Returns the specified space, optionally including its custom data object.
  ///
  /// Provide [include] List of additional/complex attributes to include in response.
  /// Omit this parameter if you don't want to retrieve additional attributes.
  ///
  /// Required field [spaceId] is the unique space identifier.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [EnsureException].
  Future<GetSpaceResult> getSpace(String spaceId,
      {Keyset keyset, String using, List<String> include}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(spaceId).isNotEmpty('spaceId');

    var params = GetSpaceParams(keyset, spaceId, include: include);

    return defaultFlow<GetSpaceParams, GetSpaceResult>(
        log: _log,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetSpaceResult.fromJson(object));
  }

  /// Updates the specified space. Returns the space object,
  /// optionally including its custom data object.
  ///
  /// You can change all of the space object's properties, except its ID.
  /// Invalid property names are silently ignored and will not cause a request to fail.
  ///
  /// If you update the "custom" property in [space], you must completely replace it;
  /// partial updates are not supported.
  /// The custom object can only contain scalar values.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [EnsureException].
  Future<UpdateSpaceResult> updateSpace(SpaceDetails space, String spaceId,
      {Keyset keyset, String using, List<String> include}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(space).isNotNull('space details');
    Ensure(spaceId).isNotEmpty('spaceId');

    var payload = await _core.parser.encode(space);

    var params = UpdateSpaceParams(keyset, payload, spaceId, include: include);

    return defaultFlow<UpdateSpaceParams, UpdateSpaceResult>(
        log: _log,
        core: _core,
        params: params,
        serialize: (object, [_]) => UpdateSpaceResult.fromJson(object));
  }

  /// Deletes the specified space.
  ///
  /// [spaceId] should be a valid identifier of the space
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, then it will throw [EnsureException].
  Future<DeleteSpaceResult> deleteSpace(String spaceId,
      {Keyset keyset, String using}) async {
    keyset ??= _core.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull('keyset');
    Ensure(spaceId).isNotEmpty('spaceId');
    var params = DeleteSpaceParams(keyset, spaceId);

    return defaultFlow<DeleteSpaceParams, DeleteSpaceResult>(
        log: _log,
        core: _core,
        params: params,
        serialize: (object, [_]) => DeleteSpaceResult.fromJson(object));
  }
}

/// Represents a Space object
class Space {
  final PubNub _core;
  final Keyset _keyset;
  final String _id;

  Space(this._core, this._keyset, this._id);

  /// You can use this method to add a users(members) into given space
  /// Provide valid [userId] to add it to space
  ///
  /// Returns true if user is added to space successfully
  Future<bool> addMembers(Set<String> memberIds) async {
    var success = false;
    var result = await _core.memberships
        .manageSpaceMembers(_id, add: memberIds, keyset: _keyset);
    success = result.status == 200;
    return success;
  }

  /// You can use this method to remove an existing users(members) from given space
  /// Provide valid [userId] to remove it from given space
  ///
  /// Returns true if user(member) is remove from given space successfully
  Future<bool> removeMembers(Set<String> memberIds) async {
    var success = false;
    var result = await _core.memberships
        .manageSpaceMembers(_id, remove: memberIds, keyset: _keyset);
    success = result.status == 200;
    return success;
  }

  /// It returns space's list of members
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
  Future<SpaceMembersResult> getMembers(
      {Set<String> include,
      int limit,
      String start,
      String end,
      bool count,
      String filter,
      Set<String> sort,
      Keyset keyset,
      String using}) async {
    return await _core.memberships.getSpaceMembers(_id,
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
