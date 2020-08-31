import 'package:meta/meta.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_endpoints/pam.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

import 'token_request.dart';

export 'token.dart' show Token;
export 'resource.dart' show Resource, ResourceType, ResourceTypeExtension;
export 'token_request.dart' show TokenRequest;

final _logger = injectLogger('pubnub.dx.pam');

mixin PamDx on Core {
  /// Use this method to modify permissions for provided [authKeys].
  ///
  /// * [ttl] signifies how long those permissions will be in place.
  /// * [channels] are set of channels for which grant permissions will be applied.
  /// * [channelGroups] are set of channel groups for which grant persmissions will be applied.
  /// * [write] is for write permission : true for allowing write operation, false to restrict
  /// * [read] is for read permission : true for allowing read operation, false to restrict
  /// * [manage] is for manage permission : true for allowing manage operation, false to restrict
  /// * [delete] is for delete permission : true for allowing delete operation, false to restrict
  Future<PamGrantResult> grant(Set<String> authKeys,
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
    Ensure(keyset).isNotNull('keyset');
    Ensure(keyset.secretKey).isNotEmpty('secretKey');

    var params = PamGrantParams(
        keyset, authKeys, '${Time().now().millisecondsSinceEpoch ~/ 1000}',
        ttl: ttl,
        channels: channels,
        channelGroups: channelGroups,
        write: write,
        read: read,
        manage: manage,
        delete: delete);

    var result = await defaultFlow<PamGrantParams, PamGrantResult>(
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
      {@required int ttl, dynamic meta, String using, Keyset keyset}) {
    Ensure(ttl).isNotNull('ttl');

    keyset ??= super.keysets.get(using, defaultIfNameIsNull: true);

    Ensure(keyset).isNotNull('keyset');

    return TokenRequest(this, keyset, ttl, meta);
  }
}
