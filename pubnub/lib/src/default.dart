import '../core.dart';

import 'networking/networking.dart';
import 'parser/parser.dart';
import 'crypto/crypto.dart';
import 'subscribe/subscribe.dart';

import 'dx/time.dart';
import 'dx/publish/publish.dart';
import 'dx/signal/signal.dart';
import 'dx/batch/batch.dart';
import 'dx/channel/channel.dart';
import 'dx/channel/channel_group.dart';
import 'dx/message_action/message_action.dart';
import 'dx/pam/pam.dart';
import 'dx/push/push.dart';
import 'dx/presence/presence.dart';
import 'dx/files/files.dart';
import 'dx/objects/objects_types.dart';
import 'dx/objects/objects.dart';
import 'dx/supervisor/supervisor.dart';

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
///
/// {@category Basic Features}
class PubNub extends Core
    with
        TimeDx,
        PublishDx,
        SubscribeDx,
        SignalDx,
        MessageActionDx,
        PushNotificationDx,
        PamDx,
        PresenceDx,
        SupervisorDx {
  /// Contains methods that allow running batch operations on channels,
  /// channel groups and other features.
  late final BatchDx batch;

  /// Contains methods that allow manipulating channel groups.
  late final ChannelGroupDx channelGroups;

  /// Contains methods to manage channel and uuids metadata and their relationships.
  late final ObjectsDx objects;

  /// Contains methods that allow managing files.
  late final FileDx files;

  /// Current version of this library.
  static String version = Core.version;

  PubNub(
      {Keyset? defaultKeyset,
      INetworkingModule? networking,
      IParserModule? parser,
      ICryptoModule? crypto})
      : super(
            defaultKeyset: defaultKeyset,
            networking: networking ?? NetworkingModule(),
            parser: parser ?? ParserModule(),
            crypto: crypto ?? CryptoModule()) {
    batch = BatchDx(this);
    channelGroups = ChannelGroupDx(this);
    objects = ObjectsDx(this);
    files = FileDx(this);
  }

  /// Returns a representation of a channel.
  ///
  /// Useful if you need to work on only one channel.
  Channel channel(String name, {Keyset? keyset, String? using}) {
    keyset ??= keysets[using];

    return Channel(this, keyset, name);
  }

  /// Creates [UUIDMetadata] and sets metadata for given [uuid] in the database.
  ///
  /// If [uuid] is null, then it uses [Keyset.uuid].
  Future<UUIDMetadata> uuidMetadata(
      {String? uuid,
      String? name,
      String? email,
      Map<String, dynamic>? custom,
      String? externalId,
      String? profileUrl,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    var result = await objects.setUUIDMetadata(
        UuidMetadataInput(
            name: name,
            email: email,
            externalId: externalId,
            profileUrl: profileUrl,
            custom: custom),
        uuid: uuid,
        keyset: keyset);
    return UUIDMetadata(objects, keyset, result.metadata.id);
  }

  /// Creates [ChannelMetadata] and sets metadata for given [channel] in the database.
  Future<ChannelMetadata> channelMetadata(String channelId,
      {String? name,
      String? description,
      Map<String, dynamic>? custom,
      Keyset? keyset,
      String? using}) async {
    keyset ??= keysets[using];

    var result = await objects.setChannelMetadata(
        channelId,
        ChannelMetadataInput(
            name: name, description: description, custom: custom),
        keyset: keyset);

    return ChannelMetadata(objects, keyset, result.metadata.id);
  }

  /// Returns a new instance of [Device] (from Push Notification API).
  ///
  /// [deviceId] should be non-empty and valid.
  Device device(String deviceId, {Keyset? keyset, String? using}) {
    keyset ??= keysets[using];
    return Device(this, keyset, deviceId);
  }
}
