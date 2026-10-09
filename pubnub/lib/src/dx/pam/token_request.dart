import 'dart:convert';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_endpoints/pam.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'resource.dart';
import 'token.dart';

/// Bit of the only permission allowed in the grant `categories` payload.
const int _categoryGet = 32;

/// Represents a token request.
///
/// {@category Access Manager}
class TokenRequest {
  final Core _core;
  final Keyset _keyset;

  /// Time to live in seconds.
  int ttl;

  final List<Resource> _resources = [];

  final List<Projection> _projections = [];

  final Set<ResourceType> _categories = {};

  /// Token metadata.
  final Map<String, dynamic>? meta;

  String? authorizedUUID;

  String? authorizedUserId;

  TokenRequest(this._core, this._keyset, this.ttl,
      {this.meta, this.authorizedUUID, this.authorizedUserId})
      : assert(authorizedUUID == null || authorizedUserId == null,
            'Either `authorizedUUID` or `authorizedUserId` is allowed');

  /// Adds new resource to this token request.
  ///
  /// Provide [name] to grant permissions to a single resource, or [pattern] to
  /// grant them to every resource matching that pattern.
  ///
  /// DataSync resource types ([ResourceType.entity],
  /// [ResourceType.relationship], [ResourceType.membership])
  /// and [ResourceType.user] only support the CRUD permissions [create], [get],
  /// [update] and [delete].
  ///
  /// **Note:** [ResourceType.user] grants permissions in the `users` scope.
  /// Use [ResourceType.uuid] for App Context UUID metadata permissions.
  void add(ResourceType type,
      {String? name,
      String? pattern,
      bool? create,
      bool? delete,
      bool? manage,
      bool? read,
      bool? write,
      bool? get,
      bool? update,
      bool? join}) {
    _resources.add(Resource(type,
        name: name,
        pattern: pattern,
        create: create,
        delete: delete,
        manage: manage,
        read: read,
        write: write,
        get: get,
        update: update,
        join: join));
  }

  /// Assigns a DataSync projection to this token request.
  ///
  /// A projection restricts which fields of the matched DataSync resources are
  /// visible. Pass [defaultProjection] to assign the base projection.
  ///
  /// Projections are supported for [ResourceType.entity],
  /// [ResourceType.relationship], [ResourceType.membership],
  /// [ResourceType.user] and [ResourceType.channel]. Exactly one of [name] or
  /// [pattern] must be provided. When a resource matches both a [name] and a
  /// [pattern] assignment, the [name] assignment takes priority.
  ///
  /// A projection does not grant any permission by itself: the resources it
  /// applies to have to be granted with [add] as well.
  void addDataSyncProjection(ResourceType type,
      {String? name, String? pattern, required String projection}) {
    if (!type.supportsProjection) {
      Ensure.fail('invalid-type', 'type', [
        'entity',
        'relationship',
        'membership',
        'user',
        'channel',
      ]);
    }

    if (name != null && pattern != null) {
      Ensure.fail('not-together', 'name', ['pattern']);
    }

    Ensure(name ?? pattern).isNotEmpty('name/pattern');
    Ensure(projection).isNotEmpty('projection');

    _projections.add(
        Projection(type, name: name, pattern: pattern, projection: projection));
  }

  /// Grants category-level `get` permission on a whole resource type.
  ///
  /// Allows listing all App Context metadata of [type] on the subscribe key:
  /// [ResourceType.channel] for channel metadata and [ResourceType.uuid] for
  /// uuid metadata. A resource-level or pattern `get` grant added with [add]
  /// does not imply this permission.
  void addCategory(ResourceType type) {
    if (!type.supportsCategory) {
      Ensure.fail('invalid-type', 'type', ['channel', 'uuid']);
    }

    _categories.add(type);
  }

  /// Sends the request to the server.
  Future<Token> send() async {
    // Projections only select which fields of the granted resources are
    // visible, so a grant without resources or categories carries no
    // permissions and is rejected by the server.
    if (_resources.isEmpty && _categories.isEmpty) {
      Ensure.fail('not-empty', 'resources/categories', []);
    }

    bool hasType(ResourceType type) =>
        _resources.any((resource) => resource.type == type);

    if (hasType(ResourceType.user) && hasType(ResourceType.uuid)) {
      Ensure.fail('not-together', 'user', ['uuid']);
    }

    if (hasType(ResourceType.space) && hasType(ResourceType.channel)) {
      Ensure.fail('not-together', 'space', ['channel']);
    }

    Map<String, dynamic> combine<T extends Pattern>(
        Map<String, dynamic> accumulator, Resource resource) {
      var type = resource.type.value;
      var name = resource.name ?? resource.pattern;

      return {
        ...accumulator,
        type: {...(accumulator[type] ?? {}), name: resource.bit}
      };
    }

    var resources = _resources
        .where((resource) => resource.name is String)
        .fold(
            {'channels': {}, 'groups': {}, 'uuids': {}, 'users': {}}, combine);

    var patterns = _resources
        .where((resource) => resource.pattern is String)
        .fold(
            {'channels': {}, 'groups': {}, 'uuids': {}, 'users': {}}, combine);

    var categories = {
      for (var type in _categories) type.categoryScope!: _categoryGet
    };

    var projections = _encodeProjections();

    var data = {
      'ttl': ttl,
      'permissions': {
        'resources': resources,
        'patterns': patterns,
        if (categories.isNotEmpty) 'categories': categories,
        if (authorizedUUID != null || authorizedUserId != null)
          'uuid': authorizedUUID ?? authorizedUserId,
        if (meta != null || projections != null)
          'meta': {
            ...?meta,
            if (projections != null) 'pn-projections': projections
          }
      }
    };

    var payload = json.encode(data);

    return defaultFlow<PamGrantTokenParams, Token>(
        keyset: _keyset,
        core: _core,
        params: PamGrantTokenParams(
          _keyset,
          payload,
        ),
        serialize: (object, [_]) {
          var result = PamGrantTokenResult.fromJson(object);

          return Token(result.token);
        });
  }

  /// Encodes the assigned projections into the `pn-projections` payload.
  ///
  /// Returns `null` when no projections have been assigned.
  Map<String, dynamic>? _encodeProjections() {
    if (_projections.isEmpty) return null;

    var resources = <String, dynamic>{};
    var patterns = <String, dynamic>{};

    for (var projection in _projections) {
      var type = projection.type.projectionScope;

      if (projection.name != null) {
        resources['$type:${projection.name}'] = projection.projection;
      } else {
        patterns['$type:${projection.pattern}'] = projection.projection;
      }
    }

    return {
      if (resources.isNotEmpty) 'res': resources,
      if (patterns.isNotEmpty) 'pat': patterns
    };
  }
}
