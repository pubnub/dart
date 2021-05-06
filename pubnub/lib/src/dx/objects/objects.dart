import 'package:pubnub/core.dart';

import '../_utils/utils.dart';
import '../_endpoints/objects/uuid_metadata.dart';
import '../_endpoints/objects/channel_metadata.dart';
import '../_endpoints/objects/membership_metadata.dart';
import 'schema.dart';

export '../_endpoints/objects/uuid_metadata.dart';
export '../_endpoints/objects/channel_metadata.dart';
export '../_endpoints/objects/membership_metadata.dart';
export 'schema.dart';

/// Groups **objects** methods together.
///
/// Available as [PubNub.objects].
/// Introduced with [Objects API](https://www.pubnub.com/docs/platform/channels/metadata).
///
/// {@category Objects}
class ObjectsDx {
  final Core _core;

  /// @nodoc
  ObjectsDx(this._core);

  /// Returns a paginated list of all uuidMetadata associated with the given subscription key,
  /// optionally including each uuidMetadata record's custom data object.
  ///
  /// To include `custom` property fields in response, set [includeCustomFields] to `true`
  /// Omit this parameter if you don't want to retrieve additional metadata.
  ///
  /// You can limit number of returned user object using [limit] parameter
  /// Default is 100, which is also the maximum value.
  ///
  /// You can specify [start] and [end] to specify previously-returned cursor bookmark
  /// for fetching the next/previous page
  ///
  /// To omit `totalCount` field from paginated list, set [includeCount] to `false`
  /// Default is `true`.
  ///
  /// [filter] is Expression used to filter the results.
  /// Only objects whose properties satisfy the given expression are returned.
  ///
  /// For sorting, use [sort] which is List of attributes to sort by.
  /// Append :asc or :desc to an attribute to specify sort direction.
  /// The default sort direction is ascending.
  Future<GetAllUuidMetadataResult> getAllUUIDMetadata(
      {bool? includeCustomFields,
      int? limit,
      String? start,
      String? end,
      bool includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }

    var params = GetAllUuidMetadataParams(keyset,
        include: include,
        limit: limit,
        start: start,
        end: end,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<GetAllUuidMetadataParams, GetAllUuidMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetAllUuidMetadataResult.fromJson(object));
  }

  /// Returns the specified uuidMetadata, optionally including uuidMetadata's custom data object.
  ///
  /// To include `custom` property fields in response, set [includeCustomFields] to `true`
  /// Omit this parameter if you don't want to retrieve additional metadata.
  ///
  /// `uuid` is Unique identifier of an end-user. It may contain up to 92 UTF-8 byte sequences.
  /// Prohibited characters are ,, /, \, *, :, channel, non-printable ASCII control characters, and Unicode zero.
  /// * If `uuid` not provided then it picks `uuid` from `keyset` or PubNub instance's `uuid`
  /// * If no `uuid` is set in PubNub instance default keyset, `keyset` does not hold uuid
  /// and `uuid`not provided in argument then it throws InvariantException
  Future<GetUuidMetadataResult> getUUIDMetadata(
      {String? uuid,
      Keyset? keyset,
      String? using,
      bool? includeCustomFields}) async {
    keyset ??= _core.keysets[using];

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }

    var params = GetUuidMetadataParams(keyset, uuid: uuid, include: include);
    return defaultFlow<GetUuidMetadataParams, GetUuidMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetUuidMetadataResult.fromJson(object));
  }

  /// Sets metadata for the specified uuid in the database.
  /// Returns the updated uuid object, optionally including custom properties.
  ///
  /// * You can change all of the uuid object's properties, except its identifier.
  /// * Invalid property names are silently ignored and will not cause a request to fail.
  /// * If you set the "custom" property, you must completely replace it; partial updates are not supported.
  /// * The custom object can only contain scalar values.
  ///
  /// To include `custom` property fields in response, set [includeCustomFields] to `true`
  /// Omit this parameter if you don't want to retrieve additional metadata.
  ///
  /// `uuid` is Unique identifier of an end-user. It may contain up to 92 UTF-8 byte sequences.
  /// Prohibited characters are ,, /, \, *, :, channel, non-printable ASCII control characters, and Unicode zero.
  /// * If `uuid` parameter is provied then it sets metadata for given uuid.
  /// * In case of null `uuid` it sets metadata for PubNub instance's `uuid`
  /// * If no `uuid` is set in PubNub instance default keyset, `keyset` does not hold uuid
  /// and `uuid` not provided in method argument then it throws InvariantException
  Future<SetUuidMetadataResult> setUUIDMetadata(
      UuidMetadataInput uuidMetadataInput,
      {String? uuid,
      bool? includeCustomFields,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];
    Ensure(uuidMetadataInput).isNotNull('uuid metadata input');

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }

    var payload = await _core.parser.encode(uuidMetadataInput);
    var params =
        SetUuidMetadataParams(keyset, payload, uuid: uuid, include: include);

    return defaultFlow<SetUuidMetadataParams, SetUuidMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => SetUuidMetadataResult.fromJson(object));
  }

  /// Deletes the specified uuid's metadata form the database.
  /// If `uuid` is provied then it deletes metadata for given uuid.
  /// In case of null `uuid` it deletes metadata for PubNub instance's `uuid`
  /// If no `uuid` is set in PubNub instance default keyset, `keyset` does not hold uuid
  /// and `uuid` not provided in argument then it throws InvariantException
  Future<RemoveUuidMetadataResult> removeUUIDMetadata(
      {String? uuid, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    var params = RemoveUuidMetadataParams(keyset, uuid: uuid);

    return defaultFlow<RemoveUuidMetadataParams, RemoveUuidMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => RemoveUuidMetadataResult.fromJson(object));
  }

  // Channel Metadata

  /// Returns a paginated list of all channelMetadata associated with the given subscription key,
  /// optionally including each channelMetadata record's custom data object.
  ///
  /// To include `custom` property fields in response, set [includeCustomFields] to `true`
  /// Omit this parameter if you don't want to retrieve additional metadata.
  ///
  /// You can limit number of returned user object using [limit] parameter
  /// Default is 100, which is also the maximum value.
  ///
  /// You can specify [start] and [end] to specify previously-returned cursor bookmark
  /// for fetching the next/previous page
  ///
  /// To omit `totalCount` field from paginated list, set [includeCount] to `false`
  /// Default is `true`.
  ///
  /// [filter] is Expression used to filter the results.
  /// Only objects whose properties satisfy the given expression are returned.
  ///
  /// For sorting, use [sort] which is List of attributes to sort by.
  /// Append :asc or :desc to an attribute to specify sort direction.
  /// The default sort direction is ascending.
  Future<GetAllChannelMetadataResult> getAllChannelMetadata(
      {int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }

    var params = GetAllChannelMetadataParams(keyset,
        include: include,
        limit: limit,
        start: start,
        end: end,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<GetAllChannelMetadataParams,
            GetAllChannelMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) =>
            GetAllChannelMetadataResult.fromJson(object));
  }

  /// Returns the specified channelMetadata, optionally including channelMetadata's custom data object.
  ///
  /// To include `custom` property fields in response, set [includeCustomFields] to `true`
  /// Omit this parameter if you don't want to retrieve additional metadata.
  ///
  /// `channelId` is Channel identifier. Must not be empty, and may contain up to 92 UTF-8 byte sequences.
  /// Prohibited characters are ,, /, \, *, :, channel, non-printable ASCII control characters, and Unicode zero.
  Future<GetChannelMetadataResult> getChannelMetadata(String channelId,
      {Keyset? keyset, String? using, bool? includeCustomFields}) async {
    keyset ??= _core.keysets[using];
    Ensure(channelId).isNotEmpty('channelIds');

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }

    var params = GetChannelMetadataParams(keyset, channelId, include: include);

    return defaultFlow<GetChannelMetadataParams, GetChannelMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => GetChannelMetadataResult.fromJson(object));
  }

  /// Sets metadata for the specified `channelId` in the database.
  /// Returns the updated uuid object, optionally including custom properties.
  /// `channelId` is Channel identifier. Must not be empty, and may contain up to 92 UTF-8 byte sequences.
  /// Prohibited characters are ,, /, \, *, :, channel, non-printable ASCII control characters, and Unicode zero.
  ///
  /// * You can change all of the channel's metadata, except its identifier.
  /// * Invalid property names are silently ignored and will not cause a request to fail.
  /// * If you set the "custom" property, you must completely replace it; partial updates are not supported.
  /// * The custom object can only contain scalar values.
  ///
  /// To include `custom` property fields in response, set [includeCustomFields] to `true`
  /// Omit this parameter if you don't want to retrieve additional metadata.
  Future<SetChannelMetadataResult> setChannelMetadata(
      String channelId, ChannelMetadataInput channelMetadataInput,
      {bool? includeCustomFields, Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotNull('channelId');
    Ensure(channelMetadataInput).isNotNull('channelMetadataInput');

    var payload = await _core.parser.encode(channelMetadataInput);

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }

    var params =
        SetChannelMetadataParams(keyset, channelId, payload, include: include);

    return defaultFlow<SetChannelMetadataParams, SetChannelMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => SetChannelMetadataResult.fromJson(object));
  }

  /// Deletes metadata for the specified channel `channelId` from the database.
  /// `channelId` is Channel identifier. Must not be empty, and may contain up to 92 UTF-8 byte sequences.
  /// Prohibited characters are ,, /, \, *, :, channel, non-printable ASCII control characters, and Unicode zero.
  Future<RemoveChannelMetadataResult> removeChannelMetadata(String channelId,
      {Keyset? keyset, String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channelId');
    var params = RemoveChannelMetadataParams(keyset, channelId);

    return defaultFlow<RemoveChannelMetadataParams,
            RemoveChannelMetadataResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) =>
            RemoveChannelMetadataResult.fromJson(object));
  }

  //UUID-Membership and Channel-Members metadata

  /// Returns the specified `uuid` channel memberships,
  /// optionally including the custom data objects for: the uuid's perspective on their membership set ("custom"),
  /// the uuid's perspective on the channel ("channel"), and the channel's custom data ("channel.custom").
  ///
  /// * If `uuid` not provided then it picks `uuid` from given `keyset` or PubNub instance's `uuid`
  /// * If no `uuid` is set in PubNub instance default keyset, `keyset` does not hold uuid
  ///   and `uuid`not provided in argument then it throws InvariantException
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
      {String? uuid,
      int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeChannelFields,
      bool? includeChannelCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeChannelFields != null && includeChannelFields) {
      include.add('channel');
    }
    if (includeChannelCustomFields != null && includeChannelCustomFields) {
      include.add('channel.custom');
    }

    var params = GetMembershipsMetadataParams(keyset,
        uuid: uuid,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<GetMembershipsMetadataParams, MembershipsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => MembershipsResult.fromJson(object));
  }

  /// Sets channel membership metadata and/or deletes memberships metadata for the specified uuid.
  /// `setMetadata` is memberships metadata input to provide metadata details
  /// It deletes uuid's membership from given `removeChannelIds` channels
  ///
  /// Returns the updated uuid's channel membership metadata, optionally including
  /// the custom data objects for: the uuid's perspective on their membership set ("custom"),
  /// the uuid's perspective on the channel ("channel"), and the channel's custom data ("channel.custom").
  ///
  /// * If `uuid` not provided then it picks `uuid` from given `keyset` or PubNub instance's `uuid`
  /// * If no `uuid` is set in PubNub instance default keyset, `keyset` does not hold uuid
  ///   and `uuid`not provided in argument then it throws InvariantException
  ///
  /// * You can change all of the membership object's properties, except its identifier.
  /// * Invalid property names are silently ignored and will not cause a request to fail.
  /// * If you set the "custom" property, you must completely replace it; partial updates are not supported.
  /// * The custom object can only contain scalar values.
  ///
  /// To include `custom` property fields of membership in response, set [includeCustomFields] to `true`
  /// To include `channel` metadata fields of uuid's membership in response, set [includeChannelFields] to `true`
  /// To include `custom` fields of membership's channelmetadata, set [includeChannelCustomFields] to `true`
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
  Future<MembershipsResult> manageMemberships(
      List<MembershipMetadataInput> setMetadata, Set<String> removeChannelIds,
      {String? uuid,
      int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeChannelFields,
      bool? includeChannelCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var manageMembershipMetadata = <String, dynamic>{};
    manageMembershipMetadata['set'] = setMetadata;
    var deleteInputs = <ChannelIdInfo>[];
    removeChannelIds.forEach((id) => deleteInputs.add(ChannelIdInfo(id)));
    manageMembershipMetadata['delete'] = deleteInputs;

    var payload = await _core.parser.encode(manageMembershipMetadata);

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeChannelFields != null && includeChannelFields) {
      include.add('channel');
    }
    if (includeChannelCustomFields != null && includeChannelCustomFields) {
      include.add('channel.custom');
    }

    var params = ManageMembershipsParams(keyset, payload,
        uuid: uuid,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<ManageMembershipsParams, MembershipsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => MembershipsResult.fromJson(object));
  }

  /// Sets channel membership metadata for the specified uuid.
  /// `setMetadata` is memberships metadata input to provide metadata details
  ///
  /// Returns the updated uuid's channel membership metadata, optionally including
  /// the custom data objects for: the uuid's perspective on their membership set ("custom"),
  /// the uuid's perspective on the channel ("channel"), and the channel's custom data ("channel.custom").
  ///
  /// * If `uuid` not provided then it picks `uuid` from given `keyset` or PubNub instance's `uuid`
  /// * If no `uuid` is set in PubNub instance default keyset, `keyset` does not hold uuid
  ///   and `uuid`not provided in argument then it throws InvariantException
  ///
  /// * You can change all of the membership object's properties, except its identifier.
  /// * Invalid property names are silently ignored and will not cause a request to fail.
  /// * If you set the "custom" property, you must completely replace it; partial updates are not supported.
  /// * The custom object can only contain scalar values.
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
      List<MembershipMetadataInput> setMetadata,
      {String? uuid,
      int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeChannelFields,
      bool? includeChannelCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var manageMembershipMetadata = <String, dynamic>{};
    manageMembershipMetadata['set'] = setMetadata;

    var payload = await _core.parser.encode(manageMembershipMetadata);

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeChannelFields != null && includeChannelFields) {
      include.add('channel');
    }
    if (includeChannelCustomFields != null && includeChannelCustomFields) {
      include.add('channel.custom');
    }

    var params = ManageMembershipsParams(keyset, payload,
        uuid: uuid,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<ManageMembershipsParams, MembershipsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => MembershipsResult.fromJson(object));
  }

  /// Deletes memberships metadata for the specified uuid.
  /// `channelIds` is set of channelIds from which specified uuid's membership metadata removed
  ///
  /// Returns the updated uuid's channel membership metadata, optionally including
  /// the custom data objects for: the uuid's perspective on their membership set ("custom"),
  /// the uuid's perspective on the channel ("channel"), and the channel's custom data ("channel.custom").
  ///
  /// To include `custom` property fields of membership in response, set [includeCustomFields] to `true`
  /// To include `channel` metadata fields of uuid's membership in response, set [includeChannelFields] to `true`
  /// To include `custom` fields of membership's channel metadata, set [includeChannelCustomFields] to `true`
  ///
  /// * If `uuid` not provided then it picks `uuid` from given `keyset` or PubNub instance's `uuid`
  /// * If no `uuid` is set in PubNub instance default keyset, `keyset` does not hold uuid
  ///   and `uuid`not provided in argument then it throws InvariantException
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
  Future<MembershipsResult> removeMemberships(Set<String> channelIds,
      {String? uuid,
      int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeChannelFields,
      bool? includeChannelCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    var manageMembershipMetadata = <String, dynamic>{};

    var deleteInputs = <ChannelIdInfo>[];
    channelIds.forEach((id) => deleteInputs.add(ChannelIdInfo(id)));
    manageMembershipMetadata['delete'] = deleteInputs;

    var payload = await _core.parser.encode(manageMembershipMetadata);

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeChannelFields != null && includeChannelFields) {
      include.add('channel');
    }
    if (includeChannelCustomFields != null && includeChannelCustomFields) {
      include.add('channel.custom');
    }

    var params = ManageMembershipsParams(keyset, payload,
        uuid: uuid,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<ManageMembershipsParams, MembershipsResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => MembershipsResult.fromJson(object));
  }

  /// Returns the members' metadata in the specified channel `channelId`,
  /// optionally including the custom data objects for: the channel's perspective on their members set ("custom"),
  /// the channel's perspective of the member ("uuid"), and the uuid's custom data ("uuid.custom").
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
  Future<ChannelMembersResult> getChannelMembers(String channelId,
      {int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeUUIDFields,
      bool? includeUUIDCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channelId');

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeUUIDFields != null && includeUUIDFields) {
      include.add('uuid');
    }
    if (includeUUIDCustomFields != null && includeUUIDCustomFields) {
      include.add('uuid.custom');
    }

    var params = GetChannelMembersParams(keyset, channelId,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<GetChannelMembersParams, ChannelMembersResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => ChannelMembersResult.fromJson(object));
  }

  /// Sets the members's metadata in the specified channel `channelId` and/or deletes members `uuids` metadata
  /// it returns members paginated list optionally including
  /// the custom data objects for: the channel's perspective on their members set ("custom"),
  /// the channel's perspective of the member ("uuid"), and the uuid's custom data ("uuid.custom").
  ///
  /// Provide `removeMemberUuids` list of member uuids for which member metadata need to be deleted
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
  Future<ChannelMembersResult> manageChannelMembers(
      String channelId,
      List<ChannelMemberMetadataInput> setMetadata,
      Set<String> removeMemberUuids,
      {int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeUUIDFields,
      bool? includeUUIDCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channelId');

    var manageInput = <String, dynamic>{};
    manageInput['set'] = setMetadata;
    var deleteInput = <UuIdInfo>[];
    removeMemberUuids.forEach((id) => deleteInput.add(UuIdInfo(id)));
    manageInput['delete'] = deleteInput;

    var membersMetadata = await _core.parser.encode(manageInput);

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeUUIDFields != null && includeUUIDFields) {
      include.add('uuid');
    }
    if (includeUUIDCustomFields != null && includeUUIDCustomFields) {
      include.add('uuid.custom');
    }

    var params = ManageChannelMembersParams(keyset, channelId, membersMetadata,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<ManageChannelMembersParams, ChannelMembersResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => ChannelMembersResult.fromJson(object));
  }

  /// Sets the members's metadata in the specified channel and returns members paginated list
  /// optionally including the custom data objects for: the channel's perspective on their members set ("custom"),
  /// the channel's perspective of the member ("uuid"), and the uuid's custom data ("uuid.custom").
  ///
  /// Provide `uuids` list of members for which member metadata need to be deleted
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
  Future<ChannelMembersResult> setChannelMembers(
      String channelId, List<ChannelMemberMetadataInput> setMetadata,
      {int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeUUIDFields,
      bool? includeUUIDCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channelId');

    var manageInput = <String, dynamic>{};
    manageInput['set'] = setMetadata;

    var membersMetadata = await _core.parser.encode(manageInput);

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeUUIDFields != null && includeUUIDFields) {
      include.add('uuid');
    }
    if (includeUUIDCustomFields != null && includeUUIDCustomFields) {
      include.add('uuid.custom');
    }

    var params = ManageChannelMembersParams(keyset, channelId, membersMetadata,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<ManageChannelMembersParams, ChannelMembersResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => ChannelMembersResult.fromJson(object));
  }

  /// Removes channel members [uuids] from the specified channel [channelId] and returns remaining members paginated list
  /// optionally including the custom data objects for: the channel's perspective on their members set ("custom"),
  /// the channel's perspective of the member ("uuid"), and the uuid's custom data ("uuid.custom").
  ///
  /// Provide `uuids` list of members for which member metadata need to be deleted
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
  Future<ChannelMembersResult> removeChannelMembers(
      String channelId, Set<String> uuids,
      {int? limit,
      String? start,
      String? end,
      bool? includeCustomFields,
      bool? includeUUIDFields,
      bool? includeUUIDCustomFields,
      bool? includeCount = true,
      String? filter,
      Set<String>? sort,
      Keyset? keyset,
      String? using}) async {
    keyset ??= _core.keysets[using];

    Ensure(channelId).isNotEmpty('channelId');

    var manageInput = <String, dynamic>{};
    var deleteInput = <UuIdInfo>[];
    uuids.forEach((id) => deleteInput.add(UuIdInfo(id)));
    manageInput['delete'] = deleteInput;

    var membersMetadata = await _core.parser.encode(manageInput);

    var include = <String>{};
    if (includeCustomFields != null && includeCustomFields) {
      include.add('custom');
    }
    if (includeUUIDFields != null && includeUUIDFields) {
      include.add('uuid');
    }
    if (includeUUIDCustomFields != null && includeUUIDCustomFields) {
      include.add('uuid.custom');
    }

    var params = ManageChannelMembersParams(keyset, channelId, membersMetadata,
        limit: limit,
        start: start,
        end: end,
        include: include,
        includeCount: includeCount,
        filter: filter,
        sort: sort);

    return defaultFlow<ManageChannelMembersParams, ChannelMembersResult>(
        keyset: keyset,
        core: _core,
        params: params,
        serialize: (object, [_]) => ChannelMembersResult.fromJson(object));
  }
}
