import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/datasync/channel.dart';
import '../_endpoints/datasync/entity.dart';
import '../_endpoints/datasync/membership.dart';
import '../_endpoints/datasync/relationship.dart';
import '../_endpoints/datasync/user.dart';
import 'schema.dart';

export '../_endpoints/datasync/channel.dart';
export '../_endpoints/datasync/entity.dart';
export '../_endpoints/datasync/membership.dart';
export '../_endpoints/datasync/relationship.dart';
export '../_endpoints/datasync/user.dart';
export 'schema.dart';
export 'subscribable.dart' show DataSyncChannel, DataSyncEntity, DataSyncUser;

final _logger = injectLogger('pubnub.dx.datasync');

/// Groups **DataSync** methods together.
///
/// Available as [PubNub.dataSync].
///
/// {@category DataSync}
class DataSyncDx {
  final Core _core;

  /// @nodoc
  DataSyncDx(this._core);

  /// Creates a new entity.
  ///
  /// [entity] describes the entity to create. Its `className` and
  /// `classVersion` are required; when `id` is omitted, the server
  /// generates one.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<CreateEntityResult> createEntity(EntityInput entity,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(entity).isNotNull('entity');
    Ensure(entity.className).isNotEmpty('class name');

    var payload = await _core.parser.encode({'data': entity});
    var params = CreateEntityParams(keyset, payload);

    _logger.fine(LogEvent(
      message: 'createEntity API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<CreateEntityParams, CreateEntityResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => CreateEntityResult.fromJson(object));
  }

  /// Lists entities of the [className] class.
  ///
  /// [classVersion] narrows the listing down to one version of the class;
  /// when omitted, the latest version is used. [classLevel] disambiguates
  /// classes that share a name at different levels.
  ///
  /// The listing is cursor based: pass the `nextCursor` of the previous result
  /// as [cursor] to obtain the next page. [limit] is the maximum number of
  /// entities per page (defaults to 20 server-side, maximum 100).
  ///
  /// [filterFast] filters against strongly consistent storage and supports a
  /// limited number of conditions, while [filter] filters against eventually
  /// consistent storage. Both use the App Context query language.
  ///
  /// [sort] is a comma separated list of field names, each optionally suffixed
  /// with `:desc`, for example `createdAt:desc,id`.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetEntitiesResult> getEntities(String className,
      {int? classVersion,
      ClassLevel? classLevel,
      String? cursor,
      int? limit,
      String? filterFast,
      String? filter,
      String? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(className).isNotEmpty('class name');

    var params = GetEntitiesParams(keyset, className,
        classVersion: classVersion,
        classLevel: classLevel,
        cursor: cursor,
        limit: limit,
        filterFast: filterFast,
        filter: filter,
        sort: sort);

    _logger.fine(LogEvent(
      message: 'getEntities API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetEntitiesParams, GetEntitiesResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetEntitiesResult.fromJson(object));
  }

  /// Returns the entity identified by [entityId].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetEntityResult> getEntity(String entityId,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(entityId).isNotEmpty('entity id');

    var params = GetEntityParams(keyset, entityId);

    _logger.fine(LogEvent(
      message: 'getEntity API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetEntityParams, GetEntityResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetEntityResult.fromJson(object));
  }

  /// Replaces the entity identified by [entityId] with [entity].
  ///
  /// This is a complete resource replacement: properties missing from [entity]
  /// are cleared. Use [updateEntity] for a partial update. The entity class
  /// itself is immutable and cannot be changed.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the entity matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<SetEntityResult> setEntity(String entityId, EntityUpdate entity,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(entityId).isNotEmpty('entity id');
    Ensure(entity).isNotNull('entity');

    var payload = await _core.parser.encode({'data': entity});
    var params = SetEntityParams(keyset, entityId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'setEntity API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<SetEntityParams, SetEntityResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => SetEntityResult.fromJson(object));
  }

  /// Partially updates the entity identified by [entityId].
  ///
  /// The change is sent as an RFC 6902 JSON Patch document. Every key of
  /// [add], [replace] and [test], every item of [remove] and both pointers of
  /// [move] and [copy] are RFC 6901 JSON Pointers: they start with `/` and are
  /// sent verbatim. No prefix is added and `.` is not a separator, so escape
  /// `~` as `~0` and `/` as `~1` inside a property name.
  ///
  /// * [add] maps a pointer to the value to add.
  /// * [replace] maps the pointer of an existing property to its new value.
  /// * [remove] lists the pointers of the properties to remove.
  /// * [move] and [copy] list [JsonPointerPair]s of `from` and `path`.
  /// * [test] maps a pointer to the value it has to hold, otherwise the whole
  ///   patch is rejected.
  ///
  /// Operations are applied in the order add, replace, remove, move, copy and
  /// test, so [test] sees the result of the other operations.
  ///
  /// | To change | Pointer |
  /// |---|---|
  /// | a payload field | `/payload/email` |
  /// | a nested payload field | `/payload/address/city` |
  /// | a payload field named `user.name` | `/payload/user.name` |
  /// | the class version | `/entityClassVersion` |
  /// | the status | `/status` |
  ///
  /// The create-time parameter name and the patch path are **not** the same.
  /// You pass `classVersion` to [EntityInput], but you patch
  /// `/entityClassVersion` — the stored property name, which is also what
  /// [EntityRecord.entityClassVersion] and real-time events carry.
  ///
  /// `entityClass` and `entityClassLevel` are immutable and cannot be patched.
  ///
  /// At least one operation has to be provided.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the entity matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<UpdateEntityResult> updateEntity(String entityId,
      {Map<String, dynamic>? add,
      Map<String, dynamic>? replace,
      List<String>? remove,
      List<JsonPointerPair>? move,
      List<JsonPointerPair>? copy,
      Map<String, dynamic>? test,
      String? ifMatchesEtag,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(entityId).isNotEmpty('entity id');

    var operations = buildJsonPatch(
        add: add,
        replace: replace,
        remove: remove,
        move: move,
        copy: copy,
        test: test);
    Ensure(operations).isNotEmpty('add, replace, remove, move, copy or test');

    var payload = await _core.parser.encode(operations);
    var params = UpdateEntityParams(keyset, entityId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'updateEntity API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<UpdateEntityParams, UpdateEntityResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => UpdateEntityResult.fromJson(object));
  }

  /// Removes the entity identified by [entityId].
  ///
  /// [ifMatchesEtag] makes the removal conditional — it succeeds only when the
  /// current `eTag` of the entity matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<RemoveEntityResult> removeEntity(String entityId,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(entityId).isNotEmpty('entity id');

    var params =
        RemoveEntityParams(keyset, entityId, ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'removeEntity API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    // A successful delete has an empty body, so there is nothing to decode.
    return defaultFlow<RemoveEntityParams, RemoveEntityResult>(
        keyset: keyset,
        core: _core,
        params: params,
        deserialize: false,
        serialize: (_, [__]) => RemoveEntityResult.empty());
  }

  /// Creates a new relationship between two entities.
  ///
  /// [relationship] describes the edge to create. Both related entities have
  /// to exist already and their classes have to satisfy the relationship
  /// class, otherwise the server rejects the call. Cardinality of the
  /// relationship class is enforced server-side as well.
  ///
  /// When `id` is omitted, the server generates one.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<CreateRelationshipResult> createRelationship(
      RelationshipInput relationship,
      {Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(relationship).isNotNull('relationship');
    Ensure(relationship.entityAId).isNotEmpty('entity a id');
    Ensure(relationship.entityBId).isNotEmpty('entity b id');
    Ensure(relationship.className).isNotEmpty('class name');

    var payload = await _core.parser.encode({'data': relationship});
    var params = CreateRelationshipParams(keyset, payload);

    _logger.fine(LogEvent(
      message: 'createRelationship API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<CreateRelationshipParams, CreateRelationshipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => CreateRelationshipResult.fromJson(object));
  }

  /// Lists relationships of the [className] class.
  ///
  /// [entityAId] and [entityBId] narrow the listing down to the relationships
  /// that have the given entity on that side of the edge.
  ///
  /// [classVersion] narrows the listing down to one version of the
  /// class; when omitted, the latest version is used.
  ///
  /// The listing is cursor based: pass the `nextCursor` of the previous result
  /// as [cursor] to obtain the next page. [limit] is the maximum number of
  /// relationships per page (defaults to 20 server-side, maximum 100).
  ///
  /// [filterFast] filters against strongly consistent storage and supports a
  /// limited number of conditions, while [filter] filters against eventually
  /// consistent storage. Both use the App Context query language.
  ///
  /// [sort] is a comma separated list of field names, each optionally suffixed
  /// with `:desc`, for example `createdAt:desc,id`.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetRelationshipsResult> getRelationships(String className,
      {int? classVersion,
      String? entityAId,
      String? entityBId,
      String? cursor,
      int? limit,
      String? filterFast,
      String? filter,
      String? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(className).isNotEmpty('class name');

    var params = GetRelationshipsParams(keyset, className,
        classVersion: classVersion,
        entityAId: entityAId,
        entityBId: entityBId,
        cursor: cursor,
        limit: limit,
        filterFast: filterFast,
        filter: filter,
        sort: sort);

    _logger.fine(LogEvent(
      message: 'getRelationships API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetRelationshipsParams, GetRelationshipsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetRelationshipsResult.fromJson(object));
  }

  /// Returns the relationship identified by [relationshipId].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetRelationshipResult> getRelationship(String relationshipId,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(relationshipId).isNotEmpty('relationship id');

    var params = GetRelationshipParams(keyset, relationshipId);

    _logger.fine(LogEvent(
      message: 'getRelationship API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetRelationshipParams, GetRelationshipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetRelationshipResult.fromJson(object));
  }

  /// Replaces the relationship identified by [relationshipId] with
  /// [relationship].
  ///
  /// This is a complete resource replacement: properties missing from
  /// [relationship] are cleared. Use [updateRelationship] for a partial
  /// update. The two related entities and the relationship class are immutable
  /// and cannot be changed.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the relationship matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<SetRelationshipResult> setRelationship(
      String relationshipId, RelationshipUpdate relationship,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(relationshipId).isNotEmpty('relationship id');
    Ensure(relationship).isNotNull('relationship');

    var payload = await _core.parser.encode({'data': relationship});
    var params = SetRelationshipParams(keyset, relationshipId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'setRelationship API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<SetRelationshipParams, SetRelationshipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => SetRelationshipResult.fromJson(object));
  }

  /// Partially updates the relationship identified by [relationshipId].
  ///
  /// The change is sent as an RFC 6902 JSON Patch document. Every key of
  /// [add], [replace] and [test], every item of [remove] and both pointers of
  /// [move] and [copy] are RFC 6901 JSON Pointers: they start with `/` and are
  /// sent verbatim. No prefix is added and `.` is not a separator, so escape
  /// `~` as `~0` and `/` as `~1` inside a property name.
  ///
  /// * [add] maps a pointer to the value to add.
  /// * [replace] maps the pointer of an existing property to its new value.
  /// * [remove] lists the pointers of the properties to remove.
  /// * [move] and [copy] list [JsonPointerPair]s of `from` and `path`.
  /// * [test] maps a pointer to the value it has to hold, otherwise the whole
  ///   patch is rejected.
  ///
  /// Operations are applied in the order add, replace, remove, move, copy and
  /// test, so [test] sees the result of the other operations.
  ///
  /// | To change | Pointer |
  /// |---|---|
  /// | a payload field | `/payload/email` |
  /// | a nested payload field | `/payload/address/city` |
  /// | a payload field named `user.name` | `/payload/user.name` |
  /// | the class version | `/relationshipClassVersion` |
  /// | the status | `/status` |
  ///
  /// The create-time parameter name and the patch path are **not** the same.
  /// You pass `classVersion` to [RelationshipInput], but you patch
  /// `/relationshipClassVersion` — the stored property name, which is also
  /// what [RelationshipRecord.relationshipClassVersion] and real-time events
  /// carry.
  ///
  /// `relationshipClass`, `entityAId` and `entityBId` are immutable and
  /// cannot be patched.
  ///
  /// At least one operation has to be provided.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the relationship matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<UpdateRelationshipResult> updateRelationship(String relationshipId,
      {Map<String, dynamic>? add,
      Map<String, dynamic>? replace,
      List<String>? remove,
      List<JsonPointerPair>? move,
      List<JsonPointerPair>? copy,
      Map<String, dynamic>? test,
      String? ifMatchesEtag,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(relationshipId).isNotEmpty('relationship id');

    var operations = buildJsonPatch(
        add: add,
        replace: replace,
        remove: remove,
        move: move,
        copy: copy,
        test: test);
    Ensure(operations).isNotEmpty('add, replace, remove, move, copy or test');

    var payload = await _core.parser.encode(operations);
    var params = UpdateRelationshipParams(keyset, relationshipId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'updateRelationship API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<UpdateRelationshipParams, UpdateRelationshipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => UpdateRelationshipResult.fromJson(object));
  }

  /// Removes the relationship identified by [relationshipId].
  ///
  /// [ifMatchesEtag] makes the removal conditional — it succeeds only when the
  /// current `eTag` of the relationship matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<RemoveRelationshipResult> removeRelationship(String relationshipId,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(relationshipId).isNotEmpty('relationship id');

    var params = RemoveRelationshipParams(keyset, relationshipId,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'removeRelationship API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    // A successful delete has an empty body, so there is nothing to decode.
    return defaultFlow<RemoveRelationshipParams, RemoveRelationshipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        deserialize: false,
        serialize: (_, [__]) => RemoveRelationshipResult.empty());
  }

  /// Creates a new user.
  ///
  /// A user is a specialized entity of the `User` class or one of its
  /// subclasses.
  ///
  /// [user] describes the user to create. Its `classVersion` is required;
  /// `className` is optional and defaults to `User` server-side. When `id` is
  /// omitted, the server generates one.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<CreateUserResult> createUser(UserInput user,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(user).isNotNull('user');

    var payload = await _core.parser.encode({'data': user});
    var params = CreateUserParams(keyset, payload);

    _logger.fine(LogEvent(
      message: 'createUser API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<CreateUserParams, CreateUserResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => CreateUserResult.fromJson(object));
  }

  /// Lists users.
  ///
  /// [className] narrows the listing down to one user class. Unlike
  /// [getEntities], it is optional — when omitted, users of every `User`
  /// subclass are listed.
  ///
  /// [classVersion] narrows the listing down to one version of the class;
  /// when omitted, the latest version is used. [classLevel] disambiguates
  /// classes that share a name at different levels.
  ///
  /// The listing is cursor based: pass the `nextCursor` of the previous result
  /// as [cursor] to obtain the next page. [limit] is the maximum number of
  /// users per page (defaults to 20 server-side, maximum 100).
  ///
  /// [filterFast] filters against strongly consistent storage and supports a
  /// limited number of conditions, while [filter] filters against eventually
  /// consistent storage. Both use the App Context query language.
  ///
  /// [sort] is a comma separated list of field names, each optionally suffixed
  /// with `:desc`, for example `createdAt:desc,id`.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetUsersResult> getUsers(
      {String? className,
      int? classVersion,
      ClassLevel? classLevel,
      String? cursor,
      int? limit,
      String? filterFast,
      String? filter,
      String? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var params = GetUsersParams(keyset,
        className: className,
        classVersion: classVersion,
        classLevel: classLevel,
        cursor: cursor,
        limit: limit,
        filterFast: filterFast,
        filter: filter,
        sort: sort);

    _logger.fine(LogEvent(
      message: 'getUsers API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetUsersParams, GetUsersResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetUsersResult.fromJson(object));
  }

  /// Returns the user identified by [userId].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetUserResult> getUser(String userId,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(userId).isNotEmpty('user id');

    var params = GetUserParams(keyset, userId);

    _logger.fine(LogEvent(
      message: 'getUser API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetUserParams, GetUserResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetUserResult.fromJson(object));
  }

  /// Replaces the user identified by [userId] with [user].
  ///
  /// This is a complete resource replacement: properties missing from [user]
  /// are cleared. Use [updateUser] for a partial update. The entity class
  /// itself is immutable and cannot be changed.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the user matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<SetUserResult> setUser(String userId, UserUpdate user,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(userId).isNotEmpty('user id');
    Ensure(user).isNotNull('user');

    var payload = await _core.parser.encode({'data': user});
    var params =
        SetUserParams(keyset, userId, payload, ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'setUser API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<SetUserParams, SetUserResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => SetUserResult.fromJson(object));
  }

  /// Partially updates the user identified by [userId].
  ///
  /// The change is sent as an RFC 6902 JSON Patch document. Every key of
  /// [add], [replace] and [test], every item of [remove] and both pointers of
  /// [move] and [copy] are RFC 6901 JSON Pointers: they start with `/` and are
  /// sent verbatim. No prefix is added and `.` is not a separator, so escape
  /// `~` as `~0` and `/` as `~1` inside a property name.
  ///
  /// * [add] maps a pointer to the value to add.
  /// * [replace] maps the pointer of an existing property to its new value.
  /// * [remove] lists the pointers of the properties to remove.
  /// * [move] and [copy] list [JsonPointerPair]s of `from` and `path`.
  /// * [test] maps a pointer to the value it has to hold, otherwise the whole
  ///   patch is rejected.
  ///
  /// Operations are applied in the order add, replace, remove, move, copy and
  /// test, so [test] sees the result of the other operations.
  ///
  /// | To change | Pointer |
  /// |---|---|
  /// | a payload field | `/payload/email` |
  /// | a nested payload field | `/payload/address/city` |
  /// | a payload field named `user.name` | `/payload/user.name` |
  /// | the class version | `/entityClassVersion` |
  /// | the status | `/status` |
  ///
  /// The create-time parameter name and the patch path are **not** the same.
  /// You pass `classVersion` to [UserInput], but you patch
  /// `/entityClassVersion` — the stored property name, which is also what
  /// [UserRecord.entityClassVersion] and real-time events carry.
  ///
  /// `entityClass` and `entityClassLevel` are immutable and cannot be patched.
  ///
  /// At least one operation has to be provided.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the user matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<UpdateUserResult> updateUser(String userId,
      {Map<String, dynamic>? add,
      Map<String, dynamic>? replace,
      List<String>? remove,
      List<JsonPointerPair>? move,
      List<JsonPointerPair>? copy,
      Map<String, dynamic>? test,
      String? ifMatchesEtag,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(userId).isNotEmpty('user id');

    var operations = buildJsonPatch(
        add: add,
        replace: replace,
        remove: remove,
        move: move,
        copy: copy,
        test: test);
    Ensure(operations).isNotEmpty('add, replace, remove, move, copy or test');

    var payload = await _core.parser.encode(operations);
    var params =
        UpdateUserParams(keyset, userId, payload, ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'updateUser API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<UpdateUserParams, UpdateUserResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => UpdateUserResult.fromJson(object));
  }

  /// Removes the user identified by [userId].
  ///
  /// [ifMatchesEtag] makes the removal conditional — it succeeds only when the
  /// current `eTag` of the user matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<RemoveUserResult> removeUser(String userId,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(userId).isNotEmpty('user id');

    var params = RemoveUserParams(keyset, userId, ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'removeUser API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    // A successful delete has an empty body, so there is nothing to decode.
    return defaultFlow<RemoveUserParams, RemoveUserResult>(
        keyset: keyset,
        core: _core,
        params: params,
        deserialize: false,
        serialize: (_, [__]) => RemoveUserResult.empty());
  }

  /// Creates a new channel.
  ///
  /// A channel is a specialized entity of the `Channel` class or one of its
  /// subclasses.
  ///
  /// [channel] describes the channel to create. Its `classVersion` is
  /// required; `className` is optional and defaults to `Channel` server-side.
  /// When `id` is omitted, the server generates one.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<CreateChannelResult> createChannel(ChannelInput channel,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channel).isNotNull('channel');

    var payload = await _core.parser.encode({'data': channel});
    var params = CreateChannelParams(keyset, payload);

    _logger.fine(LogEvent(
      message: 'createChannel API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<CreateChannelParams, CreateChannelResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => CreateChannelResult.fromJson(object));
  }

  /// Lists channels.
  ///
  /// [className] narrows the listing down to one channel class. Unlike
  /// [getEntities], it is optional — when omitted, channels of every
  /// `Channel` subclass are listed.
  ///
  /// [classVersion] narrows the listing down to one version of the class;
  /// when omitted, the latest version is used. [classLevel] disambiguates
  /// classes that share a name at different levels.
  ///
  /// The listing is cursor based: pass the `nextCursor` of the previous result
  /// as [cursor] to obtain the next page. [limit] is the maximum number of
  /// channels per page (defaults to 20 server-side, maximum 100).
  ///
  /// [filterFast] filters against strongly consistent storage and supports a
  /// limited number of conditions, while [filter] filters against eventually
  /// consistent storage. Both use the App Context query language.
  ///
  /// [sort] is a comma separated list of field names, each optionally suffixed
  /// with `:desc`, for example `createdAt:desc,id`.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetChannelsResult> getChannels(
      {String? className,
      int? classVersion,
      ClassLevel? classLevel,
      String? cursor,
      int? limit,
      String? filterFast,
      String? filter,
      String? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var params = GetChannelsParams(keyset,
        className: className,
        classVersion: classVersion,
        classLevel: classLevel,
        cursor: cursor,
        limit: limit,
        filterFast: filterFast,
        filter: filter,
        sort: sort);

    _logger.fine(LogEvent(
      message: 'getChannels API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetChannelsParams, GetChannelsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetChannelsResult.fromJson(object));
  }

  /// Returns the channel identified by [channelId].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetChannelResult> getChannel(String channelId,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channel id');

    var params = GetChannelParams(keyset, channelId);

    _logger.fine(LogEvent(
      message: 'getChannel API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetChannelParams, GetChannelResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetChannelResult.fromJson(object));
  }

  /// Replaces the channel identified by [channelId] with [channel].
  ///
  /// This is a complete resource replacement: properties missing from [channel]
  /// are cleared. Use [updateChannel] for a partial update. The entity class
  /// itself is immutable and cannot be changed.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the channel matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<SetChannelResult> setChannel(String channelId, ChannelUpdate channel,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channel id');
    Ensure(channel).isNotNull('channel');

    var payload = await _core.parser.encode({'data': channel});
    var params = SetChannelParams(keyset, channelId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'setChannel API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<SetChannelParams, SetChannelResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => SetChannelResult.fromJson(object));
  }

  /// Partially updates the channel identified by [channelId].
  ///
  /// The change is sent as an RFC 6902 JSON Patch document. Every key of
  /// [add], [replace] and [test], every item of [remove] and both pointers of
  /// [move] and [copy] are RFC 6901 JSON Pointers: they start with `/` and are
  /// sent verbatim. No prefix is added and `.` is not a separator, so escape
  /// `~` as `~0` and `/` as `~1` inside a property name.
  ///
  /// * [add] maps a pointer to the value to add.
  /// * [replace] maps the pointer of an existing property to its new value.
  /// * [remove] lists the pointers of the properties to remove.
  /// * [move] and [copy] list [JsonPointerPair]s of `from` and `path`.
  /// * [test] maps a pointer to the value it has to hold, otherwise the whole
  ///   patch is rejected.
  ///
  /// Operations are applied in the order add, replace, remove, move, copy and
  /// test, so [test] sees the result of the other operations.
  ///
  /// | To change | Pointer |
  /// |---|---|
  /// | a payload field | `/payload/email` |
  /// | a nested payload field | `/payload/address/city` |
  /// | a payload field named `user.name` | `/payload/user.name` |
  /// | the class version | `/entityClassVersion` |
  /// | the status | `/status` |
  ///
  /// The create-time parameter name and the patch path are **not** the same.
  /// You pass `classVersion` to [ChannelInput], but you patch
  /// `/entityClassVersion` — the stored property name, which is also what
  /// [ChannelRecord.entityClassVersion] and real-time events carry.
  ///
  /// `entityClass` and `entityClassLevel` are immutable and cannot be patched.
  ///
  /// At least one operation has to be provided.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the channel matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<UpdateChannelResult> updateChannel(String channelId,
      {Map<String, dynamic>? add,
      Map<String, dynamic>? replace,
      List<String>? remove,
      List<JsonPointerPair>? move,
      List<JsonPointerPair>? copy,
      Map<String, dynamic>? test,
      String? ifMatchesEtag,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channel id');

    var operations = buildJsonPatch(
        add: add,
        replace: replace,
        remove: remove,
        move: move,
        copy: copy,
        test: test);
    Ensure(operations).isNotEmpty('add, replace, remove, move, copy or test');

    var payload = await _core.parser.encode(operations);
    var params = UpdateChannelParams(keyset, channelId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'updateChannel API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<UpdateChannelParams, UpdateChannelResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => UpdateChannelResult.fromJson(object));
  }

  /// Removes the channel identified by [channelId].
  ///
  /// [ifMatchesEtag] makes the removal conditional — it succeeds only when the
  /// current `eTag` of the channel matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<RemoveChannelResult> removeChannel(String channelId,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channel id');

    var params =
        RemoveChannelParams(keyset, channelId, ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'removeChannel API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    // A successful delete has an empty body, so there is nothing to decode.
    return defaultFlow<RemoveChannelParams, RemoveChannelResult>(
        keyset: keyset,
        core: _core,
        params: params,
        deserialize: false,
        serialize: (_, [__]) => RemoveChannelResult.empty());
  }

  /// Creates a new membership between a channel and a user.
  ///
  /// A membership is a specialized relationship of the `Membership` class,
  /// with the channel on the entity A side and the user on the entity B side.
  ///
  /// [membership] describes the membership to create. Its `channelId`,
  /// `userId` and `classVersion` are required, and both the channel and the
  /// user have to exist already, otherwise the server rejects the call. When
  /// `id` is omitted, the server generates one.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<CreateMembershipResult> createMembership(MembershipInput membership,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(membership).isNotNull('membership');
    Ensure(membership.channelId).isNotEmpty('channel id');
    Ensure(membership.userId).isNotEmpty('user id');

    var payload = await _core.parser.encode({'data': membership});
    var params = CreateMembershipParams(keyset, payload);

    _logger.fine(LogEvent(
      message: 'createMembership API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<CreateMembershipParams, CreateMembershipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => CreateMembershipResult.fromJson(object));
  }

  /// Lists memberships.
  ///
  /// [userId] narrows the listing down to the memberships of one user, and
  /// [channelId] to the memberships of one channel.
  ///
  /// [classVersion] narrows the listing down to one version of the
  /// `Membership` relationship class; when omitted, the latest version is
  /// used.
  ///
  /// The listing is cursor based: pass the `nextCursor` of the previous result
  /// as [cursor] to obtain the next page. [limit] is the maximum number of
  /// memberships per page (defaults to 20 server-side, maximum 100).
  ///
  /// [filterFast] filters against strongly consistent storage and supports a
  /// limited number of conditions, while [filter] filters against eventually
  /// consistent storage. Both use the App Context query language.
  ///
  /// [sort] is a comma separated list of field names, each optionally suffixed
  /// with `:desc`, for example `createdAt:desc,id`.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetMembershipsResult> getMemberships(
      {String? userId,
      String? channelId,
      int? classVersion,
      String? cursor,
      int? limit,
      String? filterFast,
      String? filter,
      String? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var params = GetMembershipsParams(keyset,
        userId: userId,
        channelId: channelId,
        classVersion: classVersion,
        cursor: cursor,
        limit: limit,
        filterFast: filterFast,
        filter: filter,
        sort: sort);

    _logger.fine(LogEvent(
      message: 'getMemberships API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetMembershipsParams, GetMembershipsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetMembershipsResult.fromJson(object));
  }

  /// Returns the membership identified by [membershipId].
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<GetMembershipResult> getMembership(String membershipId,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(membershipId).isNotEmpty('membership id');

    var params = GetMembershipParams(keyset, membershipId);

    _logger.fine(LogEvent(
      message: 'getMembership API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<GetMembershipParams, GetMembershipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetMembershipResult.fromJson(object));
  }

  /// Replaces the membership identified by [membershipId] with [membership].
  ///
  /// This is a complete resource replacement: properties missing from
  /// [membership] are cleared. Use [updateMembership] for a partial update.
  /// The channel, the user and the relationship class are immutable and
  /// cannot be changed.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the membership matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<SetMembershipResult> setMembership(
      String membershipId, MembershipUpdate membership,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(membershipId).isNotEmpty('membership id');
    Ensure(membership).isNotNull('membership');

    var payload = await _core.parser.encode({'data': membership});
    var params = SetMembershipParams(keyset, membershipId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'setMembership API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<SetMembershipParams, SetMembershipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => SetMembershipResult.fromJson(object));
  }

  /// Partially updates the membership identified by [membershipId].
  ///
  /// The change is sent as an RFC 6902 JSON Patch document. Every key of
  /// [add], [replace] and [test], every item of [remove] and both pointers of
  /// [move] and [copy] are RFC 6901 JSON Pointers: they start with `/` and are
  /// sent verbatim. No prefix is added and `.` is not a separator, so escape
  /// `~` as `~0` and `/` as `~1` inside a property name.
  ///
  /// * [add] maps a pointer to the value to add.
  /// * [replace] maps the pointer of an existing property to its new value.
  /// * [remove] lists the pointers of the properties to remove.
  /// * [move] and [copy] list [JsonPointerPair]s of `from` and `path`.
  /// * [test] maps a pointer to the value it has to hold, otherwise the whole
  ///   patch is rejected.
  ///
  /// Operations are applied in the order add, replace, remove, move, copy and
  /// test, so [test] sees the result of the other operations.
  ///
  /// | To change | Pointer |
  /// |---|---|
  /// | a payload field | `/payload/email` |
  /// | a nested payload field | `/payload/address/city` |
  /// | a payload field named `user.name` | `/payload/user.name` |
  /// | the class version | `/relationshipClassVersion` |
  /// | the status | `/status` |
  ///
  /// The create-time parameter name and the patch path are **not** the same.
  /// You pass `classVersion` to [MembershipInput], but you patch
  /// `/relationshipClassVersion` — the stored property name, which is also
  /// what [MembershipRecord.relationshipClassVersion] and real-time events
  /// carry.
  ///
  /// `relationshipClass`, `channelId` and `userId` are immutable and cannot
  /// be patched.
  ///
  /// At least one operation has to be provided.
  ///
  /// [ifMatchesEtag] makes the write conditional — it succeeds only when the
  /// current `eTag` of the membership matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<UpdateMembershipResult> updateMembership(String membershipId,
      {Map<String, dynamic>? add,
      Map<String, dynamic>? replace,
      List<String>? remove,
      List<JsonPointerPair>? move,
      List<JsonPointerPair>? copy,
      Map<String, dynamic>? test,
      String? ifMatchesEtag,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(membershipId).isNotEmpty('membership id');

    var operations = buildJsonPatch(
        add: add,
        replace: replace,
        remove: remove,
        move: move,
        copy: copy,
        test: test);
    Ensure(operations).isNotEmpty('add, replace, remove, move, copy or test');

    var payload = await _core.parser.encode(operations);
    var params = UpdateMembershipParams(keyset, membershipId, payload,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'updateMembership API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    return defaultFlow<UpdateMembershipParams, UpdateMembershipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => UpdateMembershipResult.fromJson(object));
  }

  /// Removes the membership identified by [membershipId].
  ///
  /// [ifMatchesEtag] makes the removal conditional — it succeeds only when the
  /// current `eTag` of the membership matches, otherwise the request fails.
  ///
  /// If [keyset] is not provided, then it tries to obtain a keyset [using] name.
  /// If that fails, then it uses the default keyset.
  /// If that fails as well, it will throw [InvariantException].
  Future<RemoveMembershipResult> removeMembership(String membershipId,
      {String? ifMatchesEtag, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(membershipId).isNotEmpty('membership id');

    var params = RemoveMembershipParams(keyset, membershipId,
        ifMatchesEtag: ifMatchesEtag);

    _logger.fine(LogEvent(
      message: 'removeMembership API call with parameters:',
      details: params,
      detailsType: LogEventDetailsType.apiParametersInfo,
    ));

    // A successful delete has an empty body, so there is nothing to decode.
    return defaultFlow<RemoveMembershipParams, RemoveMembershipResult>(
        keyset: keyset,
        core: _core,
        params: params,
        deserialize: false,
        serialize: (_, [__]) => RemoveMembershipResult.empty());
  }
}
