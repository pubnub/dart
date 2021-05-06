import 'package:pubnub/core.dart';
import '../_endpoints/objects/objects_types.dart';
import 'objects.dart';
import 'schema.dart';

/// Representation of UuidMetadata object
/// Useful while dealing with one specific `uuid` details
class UUIDMetadata {
  final ObjectsDx _objects;
  final Keyset _keyset;
  final String _uuid;

  UUIDMetadata(this._objects, this._keyset, this._uuid);

  /// It adds membership metadata for given `uuid` and returns paginated list of memberships metadata
  ///
  /// To include `custom` property fields of membership in response, set [includeCustomFields] to `true`
  /// To include `channel` metadata fields of uuid's membership in response, set [includeChannelFields] to `true`
  /// To include `custom` fields of membership's channel metadata, set [includeChannelCustomFields] to `true`
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
  /// To omit `totalCount` field from paginated list, set [includeCount] to `false`
  /// Default is `true`.
  ///
  /// You can provide [sort] List of attributes to sort by.
  /// Append :asc or :desc to an attribute to specify sort direction.
  /// The default sort direction is ascending.
  Future<MembershipsResult> setMemberships(
          List<MembershipMetadataInput> membershipMetadata,
          {int? limit,
          String? start,
          String? end,
          bool? includeCustomFields,
          bool? includeChannelFields,
          bool? includeChannelCustomFields,
          bool? includeCount,
          String? filter,
          Set<String>? sort}) =>
      _objects.setMemberships(membershipMetadata,
          uuid: _uuid,
          keyset: _keyset,
          limit: limit,
          start: start,
          end: end,
          includeCustomFields: includeCustomFields,
          includeChannelFields: includeChannelFields,
          includeChannelCustomFields: includeChannelCustomFields,
          includeCount: includeCount,
          filter: filter,
          sort: sort);

  /// It returns membership metadata paginated list if `uuid`
  ///
  /// To include `custom` property fields of membership in response, set [includeCustomFields] to `true`
  /// To include `channel` metadata fields of uuid's membership in response, set [includeChannelFields] to `true`
  /// To include `custom` fields of membership's channel metadata, set [includeChannelCustomFields] to `true`
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
  /// To omit `totalCount` field from paginated list, set [includeCount] to `false`
  /// Default is `true`.
  ///
  /// You can provide [sort] List of attributes to sort by.
  /// Append :asc or :desc to an attribute to specify sort direction.
  /// The default sort direction is ascending.
  Future<MembershipsResult> getMemberships(
          {int? limit,
          String? start,
          String? end,
          bool? includeCustomFields,
          bool? includeChannelFields,
          bool? includeChannelCustomFields,
          bool? includeCount,
          String? filter,
          Set<String>? sort}) =>
      _objects.getMemberships(
          uuid: _uuid,
          limit: limit,
          start: start,
          end: end,
          includeCustomFields: includeCustomFields,
          includeChannelFields: includeChannelFields,
          includeChannelCustomFields: includeChannelCustomFields,
          includeCount: includeCount,
          filter: filter,
          sort: sort,
          keyset: _keyset);
}
