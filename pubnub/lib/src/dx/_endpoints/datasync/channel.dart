import 'package:pubnub/core.dart';

import '../../datasync/schema.dart';

const _channelContentType =
    'application/vnd.pubnub.objects.channel+json;version=1';
const _patchContentType = 'application/json-patch+json';

List<String> _basePath(Keyset keyset) =>
    ['v1', 'datasync', 'subkeys', keyset.subscribeKey, 'channels'];

class CreateChannelParams extends Parameters {
  Keyset keyset;
  String channel;

  CreateChannelParams(this.keyset, this.channel);

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
    };
  }

  @override
  Request toRequest() {
    return Request.post(
        uri: Uri(pathSegments: _basePath(keyset)),
        body: channel,
        headers: {'Content-Type': _channelContentType});
  }
}

/// Result of create channel endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class CreateChannelResult extends Result {
  final ChannelRecord _channel;

  /// Created channel.
  ChannelRecord get channel => _channel;

  CreateChannelResult._(this._channel);

  factory CreateChannelResult.fromJson(dynamic object) => CreateChannelResult._(
      ChannelRecord.fromJson(object is Map ? object['data'] : null));
}

class GetChannelsParams extends Parameters {
  Keyset keyset;
  String? className;
  int? classVersion;
  ClassLevel? classLevel;
  String? cursor;
  int? limit;
  String? filterFast;
  String? filter;
  String? sort;

  GetChannelsParams(this.keyset,
      {this.className,
      this.classVersion,
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
      if (className != null && className!.isNotEmpty)
        'entity_class': className!,
      if (classVersion != null) 'entity_class_version': '$classVersion',
      if (classLevel != null) 'entity_class_level': classLevel!.value,
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

/// Result of get channels endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetChannelsResult extends Result {
  final List<ChannelRecord> _channels;
  final DataSyncPage? _page;
  final DataSyncLinks? _links;

  /// Channels of the requested page.
  List<ChannelRecord> get channels => _channels;

  /// Pagination metadata. It is `null` when the server omits it.
  DataSyncPage? get page => _page;

  /// Opaque cursor of the next page, `null` when there are no more results.
  String? get nextCursor => _page?.nextCursor;

  /// Whether there are more results after this page.
  bool get hasNext => _page?.hasNext ?? false;

  /// Hypermedia links of the listing. It is `null` when the server omits
  /// them.
  DataSyncLinks? get links => _links;

  GetChannelsResult._(this._channels, this._page, this._links);

  factory GetChannelsResult.fromJson(dynamic object) => GetChannelsResult._(
      dataSyncRows(object)
          .map<ChannelRecord>((e) => ChannelRecord.fromJson(e))
          .toList(),
      object['meta'] != null ? DataSyncPage.fromJson(object['meta']) : null,
      DataSyncLinks.maybeFromJson(object['links']));
}

class GetChannelParams extends Parameters {
  Keyset keyset;
  String channelId;

  GetChannelParams(this.keyset, this.channelId);

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
    };
  }

  @override
  Request toRequest() {
    return Request.get(
        uri: Uri(pathSegments: [..._basePath(keyset), channelId]));
  }
}

/// Result of get channel endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class GetChannelResult extends Result {
  final ChannelRecord _channel;

  /// Requested channel.
  ChannelRecord get channel => _channel;

  GetChannelResult._(this._channel);

  factory GetChannelResult.fromJson(dynamic object) => GetChannelResult._(
      ChannelRecord.fromJson(object is Map ? object['data'] : null));
}

class SetChannelParams extends Parameters {
  Keyset keyset;
  String channelId;
  String channel;
  String? ifMatchesEtag;

  SetChannelParams(this.keyset, this.channelId, this.channel,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'channel': channel,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.put(
        uri: Uri(pathSegments: [..._basePath(keyset), channelId]),
        body: channel,
        headers: {
          'Content-Type': _channelContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of set channel endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class SetChannelResult extends Result {
  final ChannelRecord _channel;

  /// Channel after the replacement.
  ChannelRecord get channel => _channel;

  SetChannelResult._(this._channel);

  factory SetChannelResult.fromJson(dynamic object) => SetChannelResult._(
      ChannelRecord.fromJson(object is Map ? object['data'] : null));
}

class UpdateChannelParams extends Parameters {
  Keyset keyset;
  String channelId;
  String patch;
  String? ifMatchesEtag;

  UpdateChannelParams(this.keyset, this.channelId, this.patch,
      {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'patch': patch,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.patch(
        uri: Uri(pathSegments: [..._basePath(keyset), channelId]),
        body: patch,
        headers: {
          'Content-Type': _patchContentType,
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of update channel endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class UpdateChannelResult extends Result {
  final ChannelRecord _channel;

  /// Channel after the patch has been applied.
  ChannelRecord get channel => _channel;

  UpdateChannelResult._(this._channel);

  factory UpdateChannelResult.fromJson(dynamic object) => UpdateChannelResult._(
      ChannelRecord.fromJson(object is Map ? object['data'] : null));
}

class RemoveChannelParams extends Parameters {
  Keyset keyset;
  String channelId;
  String? ifMatchesEtag;

  RemoveChannelParams(this.keyset, this.channelId, {this.ifMatchesEtag});

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'ifMatchesEtag': ifMatchesEtag,
    };
  }

  @override
  Request toRequest() {
    return Request.delete(
        uri: Uri(pathSegments: [..._basePath(keyset), channelId]),
        headers: {
          if (ifMatchesEtag?.isNotEmpty ?? false) 'If-Match': ifMatchesEtag!,
        });
  }
}

/// Result of remove channel endpoint call.
///
/// {@category Results}
/// {@category DataSync}
class RemoveChannelResult extends Result {
  RemoveChannelResult._();

  /// @nodoc
  factory RemoveChannelResult.empty() => RemoveChannelResult._();
}
