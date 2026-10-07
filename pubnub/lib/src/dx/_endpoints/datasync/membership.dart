import 'package:pubnub/core.dart';

import '../../datasync/schema.dart';

const _membershipContentType =
    'application/vnd.pubnub.objects.membership+json;version=1';
const _patchContentType = 'application/json-patch+json';

List<String> _basePath(Keyset keyset) =>
    ['v1', 'datasync', 'subkeys', keyset.subscribeKey, 'memberships'];

class CreateMembershipParams extends Parameters {
  Keyset keyset;
  String membership;

  CreateMembershipParams(this.keyset, this.membership);

  Map<String, dynamic> toJson() {
    return {
      'membership': membership,
    };
  }

  @override
  Request toRequest() {
    return Request.post(
        uri: Uri(pathSegments: _basePath(keyset)),
        body: membership,
        headers: {'Content-Type': _membershipContentType});
  }
}

/// Result of create membership endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class CreateMembershipResult extends Result {
  final MembershipRecord _membership;

  /// Created membership.
  MembershipRecord get membership => _membership;

  CreateMembershipResult._(this._membership);

  factory CreateMembershipResult.fromJson(dynamic object) =>
      CreateMembershipResult._(
          MembershipRecord.fromJson(object is Map ? object['data'] : null));
}

class GetMembershipsParams extends Parameters {
  Keyset keyset;
  String? userId;
  String? channelId;
  int? classVersion;
  String? cursor;
  int? limit;
  String? filterFast;
  String? filter;
  String? sort;

  GetMembershipsParams(this.keyset,
      {this.userId,
      this.channelId,
      this.classVersion,
      this.cursor,
      this.limit,
      this.filterFast,
      this.filter,
      this.sort});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'channelId': channelId,
      'classVersion': classVersion,
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
      if (userId != null && userId!.isNotEmpty) 'user_id': userId!,
      if (channelId != null && channelId!.isNotEmpty) 'channel_id': channelId!,
      if (classVersion != null) 'relationship_class_version': '$classVersion',
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

/// Result of get memberships endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetMembershipsResult extends Result {
  final List<MembershipRecord> _memberships;
  final DataSyncPage? _page;
  final DataSyncLinks? _links;

  /// Memberships of the requested page.
  List<MembershipRecord> get memberships => _memberships;

  /// Pagination metadata. It is `null` when the server omits it.
  DataSyncPage? get page => _page;

  /// Opaque cursor of the next page, `null` when there are no more results.
  String? get nextCursor => _page?.nextCursor;

  /// Whether there are more results after this page.
  bool get hasNext => _page?.hasNext ?? false;

  /// Hypermedia links of the listing. It is `null` when the server omits
  /// them.
  DataSyncLinks? get links => _links;

  GetMembershipsResult._(this._memberships, this._page, this._links);

  factory GetMembershipsResult.fromJson(dynamic object) =>
      GetMembershipsResult._(
          dataSyncRows(object)
              .map<MembershipRecord>((e) => MembershipRecord.fromJson(e))
              .toList(),
          object['meta'] != null ? DataSyncPage.fromJson(object['meta']) : null,
          DataSyncLinks.maybeFromJson(object['links']));
}

class GetMembershipParams extends Parameters {
  Keyset keyset;
  String membershipId;

  GetMembershipParams(this.keyset, this.membershipId);

  Map<String, dynamic> toJson() {
    return {
      'membershipId': membershipId,
    };
  }

  @override
  Request toRequest() {
    return Request.get(
        uri: Uri(pathSegments: [..._basePath(keyset), membershipId]));
  }
}

/// Result of get membership endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetMembershipResult extends Result {
  final MembershipRecord _membership;

  /// Requested membership.
  MembershipRecord get membership => _membership;

  GetMembershipResult._(this._membership);

  factory GetMembershipResult.fromJson(dynamic object) => GetMembershipResult._(
      MembershipRecord.fromJson(object is Map ? object['data'] : null));
}

class SetMembershipParams extends Parameters {
  Keyset keyset;
  String membershipId;
  String membership;
  String? ifMatchesEtag;

  SetMembershipParams(this.keyset, this.membershipId, this.membership,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'membershipId': membershipId,
      'membership': membership,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.put(
        uri: Uri(pathSegments: [..._basePath(keyset), membershipId]),
        body: membership,
        headers: {
          'Content-Type': _membershipContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of set membership endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class SetMembershipResult extends Result {
  final MembershipRecord _membership;

  /// Membership after the replacement.
  MembershipRecord get membership => _membership;

  SetMembershipResult._(this._membership);

  factory SetMembershipResult.fromJson(dynamic object) => SetMembershipResult._(
      MembershipRecord.fromJson(object is Map ? object['data'] : null));
}

class UpdateMembershipParams extends Parameters {
  Keyset keyset;
  String membershipId;
  String patch;
  String? ifMatchesEtag;

  UpdateMembershipParams(this.keyset, this.membershipId, this.patch,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'membershipId': membershipId,
      'patch': patch,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.patch(
        uri: Uri(pathSegments: [..._basePath(keyset), membershipId]),
        body: patch,
        headers: {
          'Content-Type': _patchContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of update membership endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class UpdateMembershipResult extends Result {
  final MembershipRecord _membership;

  /// Membership after the patch has been applied.
  MembershipRecord get membership => _membership;

  UpdateMembershipResult._(this._membership);

  factory UpdateMembershipResult.fromJson(dynamic object) =>
      UpdateMembershipResult._(
          MembershipRecord.fromJson(object is Map ? object['data'] : null));
}

class RemoveMembershipParams extends Parameters {
  Keyset keyset;
  String membershipId;
  String? ifMatchesEtag;

  RemoveMembershipParams(this.keyset, this.membershipId, {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'membershipId': membershipId,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.delete(
        uri: Uri(pathSegments: [..._basePath(keyset), membershipId]),
        headers: {
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of remove membership endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class RemoveMembershipResult extends Result {
  RemoveMembershipResult._();

  /// @nodoc
  factory RemoveMembershipResult.empty() => RemoveMembershipResult._();
}
