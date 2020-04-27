import 'package:pubnub/src/dx/presence/presence.dart';

import 'core/core.dart';
import 'core/keyset.dart';
import 'core/net/net.dart';

import 'dx/objects/schema.dart';
import 'net/net.dart';
import 'parser/parser.dart';

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
import 'dx/objects/membership.dart';
import 'dx/objects/space.dart';
import 'dx/objects/user.dart';

/// PubNub library.
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

  /// [ChannelGroupDx] contains method that allow manipulating channel groups.
  ChannelGroupDx channelGroups;

  /// [UserDx] contains methods that provide functionality to manage users
  UserDx users;

  /// [SpaceDX] contains methods that allow manipulating spaces
  SpaceDx spaces;

  /// [MembershipDX] contains methods that allow managing members of spaces and
  /// their user's memberships
  MembershipDx memberships;

  /// Version of library.
  static String version = Core.version;

  PubNub({Keyset defaultKeyset, NetworkingModule networking})
      : super(
            defaultKeyset: defaultKeyset,
            networking: networking ?? PubNubNetworkingModule(),
            parser: PubNubParserModule()) {
    batch = BatchDx(this);
    channelGroups = ChannelGroupDx(this);
    users = UserDx(this);
    spaces = SpaceDx(this);
    memberships = MembershipDx(this);
  }

  /// Returns a representation of a channel. Useful if you only need to work
  /// on one channel.
  ///
  /// All operations on a channel will use the keyset passed into this method:
  /// * [keyset] parameter has the highest priority,
  /// * if [keyset] is null, it will try to obtain a keyset named [using],
  /// * if [using] is null, it will try to obtain the default keyset,
  /// * if default keyset is not defined, it will throw an error.
  Channel channel(String name, {Keyset keyset, String using}) {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);

    return Channel(this, keyset, name);
  }

  /// Returns a representation of a channel group. Useful if you need to work on a
  /// bunch of channels at the same time.
  ///
  /// * [keyset] parameter has the highest priority,
  /// * if [keyset] is null, it will try to obtain a keyset named [using],
  /// * if [using] is null, it will try to obtain the default keyset,
  /// * if default keyset is not defined, it will throw an error.
  ChannelGroup channelGroup(String name, {Keyset keyset, String using}) {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);

    return ChannelGroup(this, keyset, name);
  }

  /// You can use this method to create a new user
  /// It returns representation of a user which further
  /// can be used to perform that user specific operations
  Future<User> user(String userId, String name,
      {String email,
      dynamic custom,
      String externalId,
      String profileUrl,
      Keyset keyset,
      String using}) async {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);

    User usr;
    var result = await users.create(
        UserDetails(userId, name,
            email: email,
            externalId: externalId,
            profileUrl: profileUrl,
            custom: custom),
        keyset: keyset);

    var userObject = result.data;
    if (result.status == 200) {
      usr = User(this, keyset, userObject.id);
    }
    return usr;
  }

  /// You can use this method to create a new space
  /// It returns representation of a space which further
  /// can be used to perform that channel specific operations
  Future<Space> space(String spaceId, String name,
      {String description, dynamic custom, Keyset keyset, String using}) async {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);

    Space space;
    var result = await spaces.create(
        SpaceDetails(spaceId, name, description: description, custom: custom),
        keyset: keyset);

    var spaceObject = result.data;
    if (result.status == 200) {
      space = Space(this, keyset, spaceObject.id);
    }
    return space;
  }

  /// Device object with [deviceId] can be used to manage it's registration
  /// to receive Push notification from channel(s).
  /// You should provide valid non empty [deviceId]
  Device device(String deviceId, {Keyset keyset, String using}) {
    keyset ??= keysets.get(using, defaultIfNameIsNull: true);
    return Device(this, keyset, deviceId);
  }
}
