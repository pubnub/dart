import 'package:pubnub/core.dart';
import '../_endpoints/objects/objects_types.dart';
import 'objects.dart';
import 'objects_types.dart';

/// Represents a channel metadata.
///
/// Useful to deal with a specific channel's metadata.
class ChannelMetadata {
  final ObjectsDx _objects;
  final Keyset _keyset;
  final String _id;

  ChannelMetadata(this._objects, this._keyset, this._id);

  /// You can use this method to add a uuidMetadata(membersMetadata) into given channel
  ///
  /// To include `custom` property fields of member in response, set [includeCustomFields] to `true`
  /// To include `uuid` metadata fields of channel's memebrs in response, set [includeUUIDFields] to `true`
  /// To include `custom` fields of channel member's uuidMetadata, set [includeUUIDCustomFields] to `true`
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
  Future<ChannelMembersResult> setChannelMembersMetadata(
          List<ChannelMemberMetadataInput> channelMembersMetadata,
          {int? limit,
          String? start,
          String? end,
          bool? includeCustomFields,
          bool? includeUUIDFields,
          bool? includeUUIDCustomFields,
          bool? includeCount,
          String? filter,
          Set<String>? sort}) =>
      _objects.setChannelMembers(_id, channelMembersMetadata,
          limit: limit,
          start: start,
          end: end,
          includeCustomFields: includeCustomFields,
          includeUUIDFields: includeUUIDFields,
          includeUUIDCustomFields: includeUUIDCustomFields,
          includeCount: includeCount,
          filter: filter,
          sort: sort);

  /// You can use this method to remove an existing users(members) from given space
  /// Provide valid `uuids` to remove it from given channel
  ///
  /// To include `custom` property fields of member in response, set [includeCustomFields] to `true`
  /// To include `uuid` metadata fields of channel's memebrs in response, set [includeUUIDFields] to `true`
  /// To include `custom` fields of channel member's uuidMetadata, set [includeUUIDCustomFields] to `true`
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
  Future<ChannelMembersResult> removeChannelMembersMetadata(Set<String> uuids,
          {int? limit,
          String? start,
          String? end,
          bool? includeCustomFields,
          bool? includeUUIDFields,
          bool? includeUUIDCustomFields,
          bool? includeCount,
          String? filter,
          Set<String>? sort}) =>
      _objects.removeChannelMembers(_id, uuids,
          keyset: _keyset,
          limit: limit,
          start: start,
          end: end,
          includeCustomFields: includeCustomFields,
          includeUUIDFields: includeUUIDFields,
          includeUUIDCustomFields: includeUUIDCustomFields,
          includeCount: includeCount,
          filter: filter,
          sort: sort);

  /// It returns paginated list of channels members Metadata
  ///
  /// To include `custom` property fields of member in response, set [includeCustomFields] to `true`
  /// To include `uuid` metadata fields of channel's memebrs in response, set [includeUUIDFields] to `true`
  /// To include `custom` fields of channel member's uuidMetadata, set [includeUUIDCustomFields] to `true`
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
  Future<ChannelMembersResult> getChannelMembersMetadata(
          {int? limit,
          String? start,
          String? end,
          bool? includeCustomFields,
          bool? includeUUIDFields,
          bool? includeUUIDCustomFields,
          bool? includeCount,
          String? filter,
          Set<String>? sort,
          Keyset? keyset,
          String? using}) =>
      _objects.getChannelMembers(_id,
          limit: limit,
          start: start,
          end: end,
          includeCustomFields: includeCustomFields,
          includeUUIDFields: includeUUIDFields,
          includeUUIDCustomFields: includeUUIDCustomFields,
          includeCount: includeCount,
          filter: filter,
          sort: sort);
}
