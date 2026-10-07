import 'package:pubnub/core.dart';

import '../../datasync/schema.dart';

const _entityContentType =
    'application/vnd.pubnub.objects.entity+json;version=1';
const _patchContentType = 'application/json-patch+json';

List<String> _basePath(Keyset keyset) =>
    ['v1', 'datasync', 'subkeys', keyset.subscribeKey, 'entities'];

class CreateEntityParams extends Parameters {
  Keyset keyset;
  String entity;

  CreateEntityParams(this.keyset, this.entity);

  Map<String, dynamic> toJson() {
    return {
      'entity': entity,
    };
  }

  @override
  Request toRequest() {
    return Request.post(
        uri: Uri(pathSegments: _basePath(keyset)),
        body: entity,
        headers: {'Content-Type': _entityContentType});
  }
}

/// Result of create entity endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class CreateEntityResult extends Result {
  final EntityRecord _entity;

  /// Created entity.
  EntityRecord get entity => _entity;

  CreateEntityResult._(this._entity);

  factory CreateEntityResult.fromJson(dynamic object) => CreateEntityResult._(
      EntityRecord.fromJson(object is Map ? object['data'] : null));
}

class GetEntitiesParams extends Parameters {
  Keyset keyset;
  String className;
  int? classVersion;
  ClassLevel? classLevel;
  String? cursor;
  int? limit;
  String? filterFast;
  String? filter;
  String? sort;

  GetEntitiesParams(this.keyset, this.className,
      {this.classVersion,
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
      'entity_class': className,
      if (classVersion != null) 'entity_class_version': '$classVersion',
      if (classLevel != null) 'entity_class_level': classLevel!.value,
      if (cursor != null && cursor!.isNotEmpty) 'cursor': cursor!,
      if (limit != null) 'limit': '$limit',
      if (filterFast != null && filterFast!.isNotEmpty)
        'filter_fast': filterFast!,
      if (filter != null && filter!.isNotEmpty) 'filter': filter!,
      if (sort != null && sort!.isNotEmpty) 'sort': sort!,
    };

    return Request.get(
        uri: Uri(
            pathSegments: _basePath(keyset), queryParameters: queryParameters));
  }
}

/// Result of get entities endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetEntitiesResult extends Result {
  final List<EntityRecord> _entities;
  final DataSyncPage? _page;
  final DataSyncLinks? _links;

  /// Entities of the requested page.
  List<EntityRecord> get entities => _entities;

  /// Pagination metadata. It is `null` when the server omits it.
  DataSyncPage? get page => _page;

  /// Opaque cursor of the next page, `null` when there are no more results.
  String? get nextCursor => _page?.nextCursor;

  /// Whether there are more results after this page.
  bool get hasNext => _page?.hasNext ?? false;

  /// Hypermedia links of the listing. It is `null` when the server omits
  /// them.
  DataSyncLinks? get links => _links;

  GetEntitiesResult._(this._entities, this._page, this._links);

  factory GetEntitiesResult.fromJson(dynamic object) => GetEntitiesResult._(
      dataSyncRows(object)
          .map<EntityRecord>((e) => EntityRecord.fromJson(e))
          .toList(),
      object['meta'] != null ? DataSyncPage.fromJson(object['meta']) : null,
      DataSyncLinks.maybeFromJson(object['links']));
}

class GetEntityParams extends Parameters {
  Keyset keyset;
  String entityId;

  GetEntityParams(this.keyset, this.entityId);

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
    };
  }

  @override
  Request toRequest() {
    return Request.get(
        uri: Uri(pathSegments: [..._basePath(keyset), entityId]));
  }
}

/// Result of get entity endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetEntityResult extends Result {
  final EntityRecord _entity;

  /// Requested entity.
  EntityRecord get entity => _entity;

  GetEntityResult._(this._entity);

  factory GetEntityResult.fromJson(dynamic object) => GetEntityResult._(
      EntityRecord.fromJson(object is Map ? object['data'] : null));
}

class SetEntityParams extends Parameters {
  Keyset keyset;
  String entityId;
  String entity;
  String? ifMatchesEtag;

  SetEntityParams(this.keyset, this.entityId, this.entity,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entity': entity,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.put(
        uri: Uri(pathSegments: [..._basePath(keyset), entityId]),
        body: entity,
        headers: {
          'Content-Type': _entityContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of set entity endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class SetEntityResult extends Result {
  final EntityRecord _entity;

  /// Entity after the replacement.
  EntityRecord get entity => _entity;

  SetEntityResult._(this._entity);

  factory SetEntityResult.fromJson(dynamic object) => SetEntityResult._(
      EntityRecord.fromJson(object is Map ? object['data'] : null));
}

class UpdateEntityParams extends Parameters {
  Keyset keyset;
  String entityId;
  String patch;
  String? ifMatchesEtag;

  UpdateEntityParams(this.keyset, this.entityId, this.patch,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'patch': patch,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.patch(
        uri: Uri(pathSegments: [..._basePath(keyset), entityId]),
        body: patch,
        headers: {
          'Content-Type': _patchContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of update entity endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class UpdateEntityResult extends Result {
  final EntityRecord _entity;

  /// Entity after the patch has been applied.
  EntityRecord get entity => _entity;

  UpdateEntityResult._(this._entity);

  factory UpdateEntityResult.fromJson(dynamic object) => UpdateEntityResult._(
      EntityRecord.fromJson(object is Map ? object['data'] : null));
}

class RemoveEntityParams extends Parameters {
  Keyset keyset;
  String entityId;
  String? ifMatchesEtag;

  RemoveEntityParams(this.keyset, this.entityId, {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.delete(
        uri: Uri(pathSegments: [..._basePath(keyset), entityId]),
        headers: {
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of remove entity endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class RemoveEntityResult extends Result {
  RemoveEntityResult._();

  /// @nodoc
  factory RemoveEntityResult.empty() => RemoveEntityResult._();
}
