import 'dart:convert';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_endpoints/pam.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'resource.dart';
import 'token.dart';

/// Represents a token request.
///
/// {@category Access Manager}
class TokenRequest {
  final Core _core;
  final Keyset _keyset;

  /// Time to live in seconds.
  int ttl;

  final List<Resource> _resources = [];

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
  /// [name] can either be a `String` or a `RegExp`.
  /// * If [name] is a `String`, it adds a normal resource.
  /// * If [name] is a `RegExp`, it adds a pattern instead.
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

  /// Sends the request to the server.
  Future<Token> send() async {
    Ensure(_resources).isNotEmpty('resources');

    var userSpaceEntities = [ResourceType.user, ResourceType.space];
    var hasUserSpaceResourceType =
        _resources.any((resource) => userSpaceEntities.contains(resource.type));
    var hasLegacyResourceType = _resources
        .any((resource) => !userSpaceEntities.contains(resource.type));

    if (hasUserSpaceResourceType && hasLegacyResourceType) {
      Ensure.fail(
          'not-together', 'user/space', ['channel', 'uuid', 'channelGroup']);
    }
    if (authorizedUUID != null && hasUserSpaceResourceType) {
      Ensure.fail('not-together', 'authorizedUUID', ['user', 'space']);
    }
    if (authorizedUserId != null && hasLegacyResourceType) {
      Ensure.fail('not-together', 'authorizedUserId',
          ['channel', 'uuid', 'channelGroup']);
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
        .fold({'channels': {}, 'groups': {}, 'uuids': {}}, combine);

    var patterns = _resources
        .where((resource) => resource.pattern is String)
        .fold({'channels': {}, 'groups': {}, 'uuids': {}}, combine);

    var data = {
      'ttl': ttl,
      'permissions': {
        'resources': resources,
        'patterns': patterns,
        if (authorizedUUID != null || authorizedUserId != null)
          'uuid': authorizedUUID ?? authorizedUserId,
        if (meta != null) 'meta': meta
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
}
