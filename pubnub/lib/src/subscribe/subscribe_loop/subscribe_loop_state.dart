import 'package:pubnub/core.dart';

/// @nodoc
class SubscribeLoopState {
  Keyset keyset;

  Timetoken timetoken;
  int? region;

  bool isActive;

  Set<String> channels;
  Set<String> channelGroups;

  SubscribeLoopState(this.keyset,
      {Timetoken? timetoken,
      this.region,
      this.channels = const {},
      this.channelGroups = const {},
      this.isActive = false})
      : timetoken = timetoken ?? Timetoken(BigInt.zero);

  bool get shouldRun =>
      isActive && (channels.isNotEmpty || channelGroups.isNotEmpty);

  SubscribeLoopState clone(
          {Timetoken? timetoken,
          int? region,
          Set<String>? channels,
          Set<String>? channelGroups,
          bool? isActive}) =>
      SubscribeLoopState(keyset)
        ..timetoken = timetoken ?? this.timetoken
        ..region = region ?? this.region
        ..channels = channels ?? this.channels
        ..channelGroups = channelGroups ?? this.channelGroups
        ..isActive = isActive ?? this.isActive;

  @override
  bool operator ==(Object other) {
    if (other is SubscribeLoopState) {
      return isActive == other.isActive &&
          timetoken.value == other.timetoken.value &&
          region == other.region &&
          channels.containsAll(other.channels) &&
          other.channels.containsAll(channels) &&
          other.channelGroups.containsAll(channelGroups) &&
          channelGroups.containsAll(other.channelGroups);
    }

    return false;
  }
}
