import 'package:pubnub/core.dart';

import '../../datasync/schema.dart';

const _relationshipContentType =
    'application/vnd.pubnub.objects.relationship+json;version=1';
const _patchContentType = 'application/json-patch+json';

List<String> _basePath(Keyset keyset) =>
    ['v1', 'datasync', 'subkeys', keyset.subscribeKey, 'relationships'];

class CreateRelationshipParams extends Parameters {
  Keyset keyset;
  String relationship;

  CreateRelationshipParams(this.keyset, this.relationship);

  Map<String, dynamic> toJson() {
    return {
      'relationship': relationship,
    };
  }

  @override
  Request toRequest() {
    return Request.post(
        uri: Uri(pathSegments: _basePath(keyset)),
        body: relationship,
        headers: {'Content-Type': _relationshipContentType});
  }
}

/// Result of create relationship endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class CreateRelationshipResult extends Result {
  final RelationshipRecord _relationship;

  /// Created relationship.
  RelationshipRecord get relationship => _relationship;

  CreateRelationshipResult._(this._relationship);

  factory CreateRelationshipResult.fromJson(dynamic object) =>
      CreateRelationshipResult._(
          RelationshipRecord.fromJson(object is Map ? object['data'] : null));
}

class GetRelationshipsParams extends Parameters {
  Keyset keyset;
  String className;
  int? classVersion;
  String? entityAId;
  String? entityBId;
  String? cursor;
  int? limit;
  String? filterFast;
  String? filter;
  String? sort;

  GetRelationshipsParams(this.keyset, this.className,
      {this.classVersion,
      this.entityAId,
      this.entityBId,
      this.cursor,
      this.limit,
      this.filterFast,
      this.filter,
      this.sort});

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'classVersion': classVersion,
      'entityAId': entityAId,
      'entityBId': entityBId,
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
      'relationship_class': className,
      if (classVersion != null) 'relationship_class_version': '$classVersion',
      if (entityAId != null && entityAId!.isNotEmpty) 'entity_a_id': entityAId!,
      if (entityBId != null && entityBId!.isNotEmpty) 'entity_b_id': entityBId!,
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

/// Result of get relationships endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetRelationshipsResult extends Result {
  final List<RelationshipRecord> _relationships;
  final DataSyncPage? _page;
  final DataSyncLinks? _links;

  /// Relationships of the requested page.
  List<RelationshipRecord> get relationships => _relationships;

  /// Pagination metadata. It is `null` when the server omits it.
  DataSyncPage? get page => _page;

  /// Opaque cursor of the next page, `null` when there are no more results.
  String? get nextCursor => _page?.nextCursor;

  /// Whether there are more results after this page.
  bool get hasNext => _page?.hasNext ?? false;

  /// Hypermedia links of the listing. It is `null` when the server omits
  /// them.
  DataSyncLinks? get links => _links;

  GetRelationshipsResult._(this._relationships, this._page, this._links);

  factory GetRelationshipsResult.fromJson(dynamic object) =>
      GetRelationshipsResult._(
          dataSyncRows(object)
              .map<RelationshipRecord>((e) => RelationshipRecord.fromJson(e))
              .toList(),
          object['meta'] != null ? DataSyncPage.fromJson(object['meta']) : null,
          DataSyncLinks.maybeFromJson(object['links']));
}

class GetRelationshipParams extends Parameters {
  Keyset keyset;
  String relationshipId;

  GetRelationshipParams(this.keyset, this.relationshipId);

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
    };
  }

  @override
  Request toRequest() {
    return Request.get(
        uri: Uri(pathSegments: [..._basePath(keyset), relationshipId]));
  }
}

/// Result of get relationship endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetRelationshipResult extends Result {
  final RelationshipRecord _relationship;

  /// Requested relationship.
  RelationshipRecord get relationship => _relationship;

  GetRelationshipResult._(this._relationship);

  factory GetRelationshipResult.fromJson(dynamic object) =>
      GetRelationshipResult._(
          RelationshipRecord.fromJson(object is Map ? object['data'] : null));
}

class SetRelationshipParams extends Parameters {
  Keyset keyset;
  String relationshipId;
  String relationship;
  String? ifMatchesEtag;

  SetRelationshipParams(this.keyset, this.relationshipId, this.relationship,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'relationship': relationship,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.put(
        uri: Uri(pathSegments: [..._basePath(keyset), relationshipId]),
        body: relationship,
        headers: {
          'Content-Type': _relationshipContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of set relationship endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class SetRelationshipResult extends Result {
  final RelationshipRecord _relationship;

  /// Relationship after the replacement.
  RelationshipRecord get relationship => _relationship;

  SetRelationshipResult._(this._relationship);

  factory SetRelationshipResult.fromJson(dynamic object) =>
      SetRelationshipResult._(
          RelationshipRecord.fromJson(object is Map ? object['data'] : null));
}

class UpdateRelationshipParams extends Parameters {
  Keyset keyset;
  String relationshipId;
  String patch;
  String? ifMatchesEtag;

  UpdateRelationshipParams(this.keyset, this.relationshipId, this.patch,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'patch': patch,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.patch(
        uri: Uri(pathSegments: [..._basePath(keyset), relationshipId]),
        body: patch,
        headers: {
          'Content-Type': _patchContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of update relationship endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class UpdateRelationshipResult extends Result {
  final RelationshipRecord _relationship;

  /// Relationship after the patch has been applied.
  RelationshipRecord get relationship => _relationship;

  UpdateRelationshipResult._(this._relationship);

  factory UpdateRelationshipResult.fromJson(dynamic object) =>
      UpdateRelationshipResult._(
          RelationshipRecord.fromJson(object is Map ? object['data'] : null));
}

class RemoveRelationshipParams extends Parameters {
  Keyset keyset;
  String relationshipId;
  String? ifMatchesEtag;

  RemoveRelationshipParams(this.keyset, this.relationshipId,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.delete(
        uri: Uri(pathSegments: [..._basePath(keyset), relationshipId]),
        headers: {
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of remove relationship endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class RemoveRelationshipResult extends Result {
  RemoveRelationshipResult._();

  /// @nodoc
  factory RemoveRelationshipResult.empty() => RemoveRelationshipResult._();
}
