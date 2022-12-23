import 'package:meta/meta.dart';

import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_endpoints/pam.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'token.dart';
import 'token_request.dart';
import 'extensions/keyset.dart';

export 'package:pubnub/src/dx/_endpoints/pam.dart'
    show PamGrantResult, PamGrantTokenResult, PamRevokeTokenResult;
export 'token.dart' show Token;
export 'resource.dart' show Resource, ResourceType, ResourceTypeExtension;
export 'extensions/keyset.dart' show PamKeysetExtension;
export 'token_request.dart' show TokenRequest;

final _logger = injectLogger('pubnub.dx.pam');

mixin PamDx on Core {
  /// Use this method to modify permissions for provided [authKeys].
  ///
  /// * [ttl] signifies how long those permissions will be in place.
  /// * [channels] are set of channels for which grant permissions will be applied.
  /// * [channelGroups] are set of channel groups for which grant persmissions will be applied.
  /// * [uuids] are set of target user ids for which grant permissions will be applied.
  /// * [write] is for write permission : true for allowing write operation, false to restrict
  /// * [read] is for read permission : true for allowing read operation, false to restrict
  /// * [manage] is for manage permission : true for allowing manage operation, false to restrict
  /// * [delete] is for delete permission : true for allowing delete operation, false to restrict
  /// * [get] is for get permission: true for allowing get operations, false to restrict
  /// * [update] is for update permission: true for allowing update opertaions, false to restrict
  /// * [join] for join permission: true for allowing join operations, false to restrict
  ///
  /// ** Permissions can not be modified for channels/channel groups AND UUID(s) (user(s)) in a single method call
  Future<PamGrantResult> grant(Set<String> authKeys,
      {int? ttl,
      Set<String>? channels,
      Set<String>? channelGroups,
      Set<String>? uuids,
      bool? write,
      bool? read,
      bool? manage,
      bool? delete,
      bool? get,
      bool? update,
      bool? join,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];
    Ensure(keyset.secretKey).isNotNull('secretKey');

    if ((uuids != null && uuids.isNotEmpty) &&
        ((channels != null && channels.isNotEmpty) ||
            (channelGroups != null && channelGroups.isNotEmpty))) {
      Ensure.fail('not-together', 'channles/channelGroups', ['uuids']);
    }
    var params = PamGrantParams(keyset, authKeys,
        ttl: ttl,
        channels: channels,
        channelGroups: channelGroups,
        uuids: uuids,
        write: write,
        read: read,
        manage: manage,
        delete: delete,
        get: get,
        update: update,
        join: join);

    var result = await defaultFlow<PamGrantParams, PamGrantResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => PamGrantResult.fromJson(object));

    if (result.warning) {
      _logger.warning(result.message);
    }

    return result;
  }

  /// Creates a [TokenRequest] that can be used to obtain a [Token].
  TokenRequest requestToken(
      {@required int? ttl,
      Map<String, dynamic>? meta,
      String? authorizedUUID,
      String? authorizedUserId,
      String? using,
      Keyset? keyset}) {
    Ensure(ttl).isNotNull('ttl');

    keyset ??= keysets[using];

    return TokenRequest(this, keyset, ttl!,
        meta: meta,
        authorizedUUID: authorizedUUID,
        authorizedUserId: authorizedUserId);
  }

  Future<Token> grantToken(TokenRequest tokenRequest) {
    return tokenRequest.send();
  }

  Token parseToken(String token) {
    return Token(token);
  }

  void setToken(String token, {String? using, Keyset? keyset}) {
    keyset ??= keysets[using];
    keyset.token = token;
  }

  Future<PamRevokeTokenResult> revokeToken(String token,
      {String? using, Keyset? keyset}) async {
    keyset ??= keysets[using];

    Ensure(keyset.secretKey).isNotNull('secretKey');
    Ensure(token).isNotEmpty('token');

    var params = PamRevokeTokenParams(keyset, (token));

    var result = await defaultFlow<PamRevokeTokenParams, PamRevokeTokenResult>(
        keyset: keyset,
        core: this,
        params: params,
        serialize: (object, [_]) => PamRevokeTokenResult.fromJson(object));

    return result;
  }
}
