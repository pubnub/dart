import 'dart:convert';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_endpoints/pam.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'resource.dart';
import 'token.dart';

class TokenRequest {
  final Core _core;
  final Keyset _keyset;

  final int ttl;
  final dynamic meta;

  final List<Resource> _resources = [];

  TokenRequest(this._core, this._keyset, this.ttl, [this.meta]);

  /// Adds new resource to this token request.
  ///
  /// [name] can either be a `String` or a `RegExp`.
  /// * If [name] is a `String`, it adds a normal resource.
  /// * If [name] is a `RegExp`, it adds a pattern instead.
  void add(ResourceType type, Pattern name,
      {bool create, bool delete, bool manage, bool read, bool write}) {
    _resources.add(Resource(type, name,
        create: create,
        delete: delete,
        manage: manage,
        read: read,
        write: write));
  }

  /// Sends the request to the server.
  Future<Token> send() async {
    Ensure(_resources).isNotEmpty('resources');

    Map<String, dynamic> combine<T extends Pattern>(
        Map<String, dynamic> accumulator, Resource resource) {
      var type = resource.type.value;
      var name = resource.name is String
          ? resource.name
          : (resource.name as RegExp).pattern;

      return {
        ...accumulator,
        type: {...(accumulator[type] ?? {}), name: resource.bit}
      };
    }

    var resources = _resources
        .where((resource) => resource.name is String)
        .fold(
            {'channels': {}, 'groups': {}, 'users': {}, 'spaces': {}}, combine);

    var patterns = _resources.where((resource) => resource.name is RegExp).fold(
        {'channels': {}, 'groups': {}, 'users': {}, 'spaces': {}}, combine);

    var data = {
      'ttl': ttl,
      'permissions': {
        'resources': resources,
        'patterns': patterns,
        'meta': meta
      }
    };

    var payload = json.encode(data);

    return defaultFlow<PamGrantTokenParams, Token>(
        core: _core,
        params: PamGrantTokenParams(
            _keyset, payload, '${Time().now().millisecondsSinceEpoch ~/ 1000}'),
        serialize: (object, [_]) {
          var result = PamGrantTokenResult.fromJson(object);

          return Token(result.token);
        });
  }
}
