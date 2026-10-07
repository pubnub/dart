import 'package:pubnub/core.dart';
import 'package:pubnub/src/default.dart';

import '../../subscribe/subscription.dart';
import '../_utils/utils.dart';

/// @nodoc
abstract class DataSyncSubscribable {
  final PubNub _pubnub;
  final Keyset _keyset;

  /// Identifier of this DataSync object.
  final String id;

  /// @nodoc
  DataSyncSubscribable(this._pubnub, this._keyset, this.id) {
    Ensure(id).isNotEmpty('id');
  }

  /// Creates an inactive subscription to this DataSync object.
  ///
  /// Activate it by calling [Subscription.subscribe]. Events are delivered
  /// on [Subscription.dataSync].
  ///
  /// [projection] selects the DataSync projection to observe. It follows the
  /// same rules as `withProjection` on [PubNub.subscribe].
  ///
  /// ```dart
  /// var base = pubnub.dataSyncUser('u1').subscription();
  /// base.subscribe();
  ///
  /// var admin =
  ///     pubnub.dataSyncUser('u1').subscription(projection: 'admin');
  /// admin.subscribe();
  /// // Observes `__admin__u1`.
  /// ```
  ///
  /// {@template pubnub.subscribe.projectionRules}
  /// * `null`, a blank name, `default` and `__default__` refer to the base
  ///   projection, so the channels are subscribed as they are.
  /// * Ids are used verbatim, so wildcards like `customer.*` work. Do not
  ///   pass ids that already carry a projection prefix.
  /// * To observe several projections of the same object, create one
  ///   subscription per projection.
  /// {@endtemplate}
  ///
  /// [timetoken] is the time to start receiving events from.
  Subscription subscription({String? projection, Timetoken? timetoken}) {
    return _pubnub.subscription(
        channels: {id},
        withProjection: projection,
        keyset: _keyset,
        timetoken: timetoken);
  }
}

/// Real-time handle for one DataSync user.
///
/// It shouldn't be instantiated directly, instead call [PubNub.dataSyncUser].
///
/// {@category DataSync}
class DataSyncUser extends DataSyncSubscribable {
  /// @nodoc
  DataSyncUser(PubNub pubnub, Keyset keyset, String id)
      : super(pubnub, keyset, id);
}

/// Real-time handle for one DataSync channel.
///
/// It shouldn't be instantiated directly, instead call
/// [PubNub.dataSyncChannel].
///
/// {@category DataSync}
class DataSyncChannel extends DataSyncSubscribable {
  /// @nodoc
  DataSyncChannel(PubNub pubnub, Keyset keyset, String id)
      : super(pubnub, keyset, id);
}

/// Real-time handle for one DataSync entity.
///
/// It shouldn't be instantiated directly, instead call [PubNub.dataSyncEntity].
///
/// {@category DataSync}
class DataSyncEntity extends DataSyncSubscribable {
  /// @nodoc
  DataSyncEntity(PubNub pubnub, Keyset keyset, String id)
      : super(pubnub, keyset, id);
}
