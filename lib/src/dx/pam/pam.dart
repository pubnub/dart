import 'package:logging/logging.dart';
import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'package:pubnub/src/dx/_endpoints/pam.dart';
import 'extensions/keyset.dart';

import 'cbor.dart';

final log = Logger('pubnub.dx.PAM');

enum GrantBit { create, delete, manage, write, read }
enum ResourceType { channel, channelGroup, user, space }

extension GrantBitExtension on GrantBit {
  int get value {
    switch (this) {
      case GrantBit.create:
        return 16;
      case GrantBit.delete:
        return 8;
      case GrantBit.manage:
        return 4;
      case GrantBit.write:
        return 2;
      case GrantBit.read:
        return 1;
      default:
        return null;
    }
  }
}

extension ResourceTypeExtension on ResourceType {
  String get value {
    switch (this) {
      case ResourceType.channel:
        return 'chan';
      case ResourceType.channelGroup:
        return 'grp';
      case ResourceType.user:
        return 'usr';
      case ResourceType.space:
        return 'spc';
      default:
        return null;
    }
  }
}

mixin PamDX on Core {
  /// Use this method to modify permissions for provided keys [authKeys]
  /// Here [authkeys] are set of keys which you want to modify permissions on
  /// [ttl] is Time To Live optional parameter
  /// [channels] are set of channels for which grant permissions will be applied
  /// [channelGroups] are set of channel groups for which grant persmissions will be applied
  /// [write] is for write permission : true for allowing write operation, false to restrict
  /// [read] is for read permission : true for allowing read operation, false to restrict
  /// [manage] is for manage permission : true for allowing manage operation, false to restrict
  /// [delete] is for delete permission : true for allowing delete operation, false to restrict
  Future<GrantResult> grant(Set<String> authKeys,
      {int ttl,
      Set<String> channels,
      Set<String> channelGroups,
      bool write,
      bool read,
      bool manage,
      bool delete,
      Keyset keyset,
      String using}) async {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");
    Ensure(keyset.authKey)
        .isNotNull("Auth key is required to modify access manager permissions");
    Ensure(keyset.authKey).isNotEmpty("Auth key can not be empty");

    var params = GrantParams(keyset, authKeys,
        ttl: ttl,
        channels: channels,
        channelGroups: channelGroups,
        write: write,
        read: read,
        manage: manage,
        delete: delete);

    return await defaultFlow<GrantParams, GrantResult>(
        log: log,
        core: this,
        params: params,
        serialize: (object, [_]) => GrantResult.fromJson(object));
  }

  /// You can use this functionality to get a signed token that can be used
  /// to access the requested resources for a specific duration.
  ///
  /// detailed permission information should be provided in [grantTokenInput]
  Future<GrantTokenResult> grantToken(GrantTokenInput grantTokenInput,
      {Keyset keyset, String using}) async {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");
    Ensure(keyset.authKey)
        .isNotNull("Auth key is required to modify access manager permissions");

    Ensure(grantTokenInput.patterns)
        .isNotNull("Patterns property of GrantTokenInput can not be null");
    Ensure(grantTokenInput.resources)
        .isNotNull("resources property of GrantTokenInput can not be null");

    Ensure(keyset.authKey).isNotEmpty("Auth key can not be empty");

    var payload = await parser.encode(grantTokenInput);

    var params = GrantTokenParams(keyset, payload);

    return await defaultFlow<GrantTokenParams, GrantTokenResult>(
        log: log,
        core: this,
        params: params,
        serialize: (object, [_]) => GrantTokenResult.fromJson(object));
  }

  /// Stores given set of [tokens]
  /// It fetches the details from the token by decoding the token strings
  /// Mapping is maintined based on resource types information encoded in token string
  /// Provide [keyset] information for which you want to store the tokens
  void setTokens(Set<String> tokens, {Keyset keyset, String using}) {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");
    tokens.forEach((token) => setToken(token, keyset: keyset, using: using));
  }

  /// Stores [token] information
  /// It fetches all the details from the [token] string which contains permissions information
  /// Mapping is maintined based on resource types information encoded in token string
  /// Provide [keyset] information for which you want to store the tokens
  void setToken(String token, {Keyset keyset, String using}) {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");
    Ensure(token).isNotEmpty("token can not be empty");
    var tokenObject = parseToken(token);
    tokenObject.resources.forEach((resourceType, resource) =>
        keyset.addResourceTokens(resourceType,
            (resource as Map).map((id, permissions) => MapEntry(id, token))));

    tokenObject.patterns.forEach((resourceType, resource) =>
        keyset.addResourcePatternTokens(
            resourceType,
            ((resource as Map)
                .map((pattern, permissions) => MapEntry(pattern, token)))));
  }

  /// It parses the token string and returns token object
  /// Token object contains mapping of resources and it's permisions
  Token parseToken(String token) {
    return decode(token);
  }

  /// It retrives token string based on resource type [type] and [resourceId] provided
  /// Returns null if no token found with give [resourceId]
  /// [type] is enum which can be [channel, channelGroup, user, space]
  /// It may returns token which is applicable to All resources of that type
  /// Provide [keyset] information for which you want to get the token
  String getToken(ResourceType type, String resourceId,
      {Keyset keyset, String using}) {
    String token = '';
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");
    token = keyset.resourceTokens[type.value][resourceId];
    if (token == null) {
      var patterns = keyset.patternTokens[type.value].keys;
      patterns.forEach((pattern) => {
            if (RegExp(pattern).hasMatch(resourceId))
              token = keyset.patternTokens[type.value][pattern]
          });
    }
    return token;
  }

  /// You can use this method to get all token strings which are aligned to Resource type [type]
  /// Provide [keyset] information for which you want to get the tokens
  Set<String> getTokens(ResourceType type, {Keyset keyset, String using}) {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");
    Set<String> result = <String>{};

    return result
      ..addAll(keyset.resourceTokens[type.value] != null
          ? keyset.resourceTokens[type.value].values
          : {})
      ..addAll(keyset.patternTokens[type.value] != null
          ? keyset.patternTokens[type.value].values
          : {});
  }

  /// Removes all the stored tokens
  /// Provide [keyset] information for which you want to clear the tokens
  void removeAllTokens({Keyset keyset, String using}) {
    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);
    Ensure(keyset).isNotNull(
        "Keyset cannot be null. Either add a default one or pass an instance to this method");
    keyset..resourceTokens.clear()..patternTokens.clear();
  }
} // End of mixin

class GrantTokenRequest {
  int _ttl;
  Resources _resources;
  Patterns _patterns;
  dynamic _meta;

  GrantTokenRequest(this._ttl);

  int get ttl => _ttl;
  set ttl(int inTtl) {
    _ttl = inTtl;
  }

  Resources get resources => _resources;
  set resources(Resources inResource) => _resources = inResource;

  Patterns get patterns => _patterns;
  set patterns(Patterns inPatterns) => _patterns = inPatterns;

  dynamic get meta => _meta;
  set meta(dynamic inMeta) => _meta = inMeta;

  GrantTokenInput build() => GrantTokenInput(this);
}

class GrantTokenInput {
  int _ttl;
  Resources _resources;
  Patterns _patterns;
  dynamic _meta;

  GrantTokenInput(GrantTokenRequest request) {
    _ttl = request.ttl;
    _resources = request.resources;
    _patterns = request.patterns;
    _meta = request.meta;
  }

  int get ttl => _ttl;

  Resources get resources => _resources;

  Patterns get patterns => _patterns;

  dynamic get meta => _meta;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ttl': _ttl,
      'resources': _resources,
      'patterns': _patterns,
      'meta': _meta,
    };
  }
}

class Permissions {
  bool _create = false;
  bool _read = false;
  bool _write = false;
  bool _manage = false;
  bool _delete = false;

  bool get create => _create;
  set create(bool create) => _create = create;

  bool get read => _read;
  set read(bool read) => _read = read;

  bool get write => _write;
  set write(bool write) => _write = write;

  bool get manage => _manage;
  set manage(bool manage) => _manage = manage;

  bool get delete => _delete;
  set delete(bool delete) => _delete = delete;

  Permissions();

  int toJson() {
    int result = 0;
    if (_create) result |= GrantBit.create.value;
    if (_delete) result |= GrantBit.delete.value;
    if (_manage) result |= GrantBit.manage.value;
    if (_write) result |= GrantBit.write.value;
    if (_read) result |= GrantBit.read.value;
    return result;
  }

  factory Permissions.fromInt(int value) {
    return Permissions()
      .._create = (value & GrantBit.create.value == GrantBit.create.value)
          ? true
          : false
      .._delete = (value & GrantBit.delete.value == GrantBit.delete.value)
          ? true
          : false
      .._manage = (value & GrantBit.manage.value == GrantBit.manage.value)
          ? true
          : false
      .._write =
          (value & GrantBit.write.value == GrantBit.write.value) ? true : false
      .._read =
          (value & GrantBit.read.value == GrantBit.read.value) ? true : false;
  }
}

class Resources {
  Map<String, Permissions> _channels;
  Map<String, Permissions> _groups;
  Map<String, Permissions> _users;
  Map<String, Permissions> _spaces;

  Resources();

  Map<String, Permissions> get channels => _channels;
  set channels(Map<String, Permissions> inChannels) => _channels = inChannels;

  Map<String, Permissions> get groups => _groups;
  set groups(Map<String, Permissions> inGroups) => _groups = inGroups;

  Map<String, Permissions> get users => _groups;
  set users(Map<String, Permissions> inUsers) => _users = inUsers;

  Map<String, Permissions> get spaces => _spaces;
  set spaces(Map<String, Permissions> inSpaces) => _spaces = inSpaces;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'channels': _channels,
      'groups': _groups,
      'users': _users,
      'spaces': _spaces,
    };
  }
}

class Patterns {
  Map<String, Permissions> _channels;
  Map<String, Permissions> _groups;
  Map<String, Permissions> _users;
  Map<String, Permissions> _spaces;

  Patterns();

  Map<String, Permissions> get channels => _channels;
  set channels(Map<String, Permissions> inChannels) => _channels = inChannels;

  Map<String, Permissions> get groups => _groups;
  set groups(Map<String, Permissions> inGroups) => _groups = inGroups;

  Map<String, Permissions> get users => _groups;
  set users(Map<String, Permissions> inUsers) => _users = inUsers;

  Map<String, Permissions> get spaces => _spaces;
  set spaces(Map<String, Permissions> inSpaces) => _spaces = inSpaces;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'channels': _channels,
      'groups': _groups,
      'users': _users,
      'spaces': _spaces,
    };
  }
}
