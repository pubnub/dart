import 'core/core.dart';

import 'net/net.dart';
import 'parser/parser.dart';
import 'crypto/crypto.dart';

import 'dx/time.dart';
import 'dx/publish/publish.dart';
import 'dx/subscribe/subscribe.dart';
import 'dx/signal/signal.dart';
import 'dx/batch/batch.dart';
import 'dx/channel/channel.dart';
import 'dx/channel/channel_group.dart';
import 'dx/message_action/message_action.dart';
import 'dx/pam/pam.dart';
import 'dx/push/push.dart';
import 'dx/presence/presence.dart';
import 'dx/objects/objects_types.dart';
import 'dx/objects/objects.dart';

/// PubNub library.
///
/// All methods on this instance accept two named parameters: `keyset` and `using`.
/// * `keyset` accepts an instance of [Keyset],
/// * `using` accepts a String name of a keyset that was defined using `pubnub.keysets.add` method.
///
/// Both of those parameters are used to obtain an instance of [Keyset] that will be used in subsequent operations.
///
/// > **Example**: In case of method [channel], all operations on a returned [Channel] instance
/// > will be executed with a keyset that was obtained when the [channel] method was called.
///
///
/// At the beginning, the method that you call will try to obtain the keyset in accordance to those rules:
/// * `keyset` parameter has the highest priority,
/// * if `keyset` is null, it will try to obtain a keyset named `using`,
/// * if `using` is null, it will try to obtain the default keyset,
/// * if default keyset is not defined, it will throw an error.
class PubNub extends Core
    with
        TimeDx,
        PublishDx,
        SubscribeDx,
        SignalDx,
        MessageActionDx,
        PushNotificationDx,
        PamDx,
        PresenceDx {
  /// [BatchDx] contains methods that allow running batch operations on channels,
  /// channel groups and other features.
  BatchDx batch;

  /// [ChannelGroupDx] contains methods that allow manipulating channel groups.
  ChannelGroupDx channelGroups;

  /// [ObjectsDx] contains methods to manage channel, uuid metadata and
  /// UUID's membership and Channel's members
  ObjectsDx objects;

  /// Current version of this library.
  static String version = Core.version;

  PubNub(
      {Keyset defaultKeyset,
      NetworkModule networking,
      ParserModule parser,
      CryptoModule crypto})
      : super(
            defaultKeyset: defaultKeyset,
            networking: networking ?? PubNubNetworkingModule(),
            parser: parser ?? PubNubParserModule(),
            crypto: crypto ?? PubNubCryptoModule()) {
    batch = BatchDx(this);
    channelGroups = ChannelGroupDx(this);
    objects = ObjectsDx(this);
  }

  /// Returns a representation of a channel.
  ///
  /// Useful if you only need to work on one channel.
  Channel channel(String name, {Keyset keyset, String using}) {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);

    return Channel(this, keyset, name);
  }

  /// Returns a representation of a channel group.
  ///
  /// Useful if you need to work on a bunch of channels at the same time.
  ChannelGroup channelGroup(String name, {Keyset keyset, String using}) {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);

    return ChannelGroup(this, keyset, name);
  }

  /// Creates [UUIDMetadata], sets metadata for given `uuid` to the database
  /// * If `uuid` argument is null then it picks `uuid` of `keyset`
  /// Returned [UUIDMetadata] instance is further useful to manage it's membership metadata
  Future<UUIDMetadata> uuidMetadata(
      {String uuid,
      String name,
      String email,
      Map<String, dynamic> custom,
      String externalId,
      String profileUrl,
      Keyset keyset,
      String using}) async {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);
    UUIDMetadata uuidMetadata;
    var result = await objects.setUUIDMetadata(
        UuidMetadataInput(
            name: name,
            email: email,
            externalId: externalId,
            profileUrl: profileUrl,
            custom: custom),
        uuid: uuid,
        keyset: keyset);
    if (result.metadata != null) {
      uuidMetadata = UUIDMetadata(this, keyset, result.metadata.id);
    }
    return uuidMetadata;
  }

  /// Creates and returns a new instance of [ChannelMetadata] (from Objects API).
  Future<ChannelMetadata> channelMetadata(String channelId,
      {String name,
      String description,
      Map<String, dynamic> custom,
      Keyset keyset,
      String using}) async {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);

    ChannelMetadata channelMetadata;
    var result = await objects.setChannelMetadata(
        channelId,
        ChannelMetadataInput(
            name: name, description: description, custom: custom),
        keyset: keyset);

    if (result.metadata != null) {
      channelMetadata = ChannelMetadata(this, keyset, result.metadata.id);
    }
    return channelMetadata;
  }

  /// Returns a new instance of [Device] (from Push Notification API).
  ///
  /// [deviceId] should be non-empty and valid.
  Device device(String deviceId, {Keyset keyset, String using}) {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);
    return Device(this, keyset, deviceId);
  }
}
