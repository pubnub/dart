import 'package:pubnub/core.dart';

/// @nodoc
class SubscribeLoopState {
  final Keyset keyset;

  final Timetoken timetoken;
  final int? region;
  final Timetoken? customTimetoken;

  final bool isActive;
  final bool isErrored;

  final Set<String> channels;
  final Set<String> channelGroups;

  SubscribeLoopState(this.keyset,
      {Timetoken? timetoken,
      this.region,
      this.channels = const {},
      this.channelGroups = const {},
      this.isActive = false,
      this.isErrored = false,
      this.customTimetoken})
      : timetoken = timetoken ?? Timetoken(BigInt.zero);

  bool get shouldRun =>
      isActive &&
      !isErrored &&
      (channels.isNotEmpty || channelGroups.isNotEmpty);

  SubscribeLoopState clone(
          {Timetoken? timetoken,
          int? region,
          Set<String>? channels,
          Set<String>? channelGroups,
          bool? isActive,
          bool? isErrored,
          Timetoken? customTimetoken}) =>
      SubscribeLoopState(
        keyset,
        timetoken: timetoken ?? this.timetoken,
        region: region ?? this.region,
        channels: channels ?? this.channels,
        channelGroups: channelGroups ?? this.channelGroups,
        isActive: isActive ?? this.isActive,
        isErrored: isErrored ?? this.isErrored,
        customTimetoken: timetoken == null
            ? customTimetoken ?? this.customTimetoken
            : customTimetoken,
      );

  @override
  bool operator ==(Object other) {
    if (other is SubscribeLoopState) {
      return isActive == other.isActive &&
          isErrored == other.isErrored &&
          timetoken.value == other.timetoken.value &&
          region == other.region &&
          channels.containsAll(other.channels) &&
          other.channels.containsAll(channels) &&
          other.channelGroups.containsAll(channelGroups) &&
          channelGroups.containsAll(other.channelGroups);
    }

    return false;
  }

  @override
  String toString() {
    var parts = <String>[];
    parts.add('active: $isActive');
    parts.add('errored: $isErrored');
    parts.add('timetoken: ${timetoken.value}');
    if (region != null) parts.add('region: $region');
    if (customTimetoken != null) {
      parts.add('customTimetoken: ${customTimetoken?.value}');
    }
    if (channels.isNotEmpty) parts.add('channels: ${channels.join(", ")}');
    if (channelGroups.isNotEmpty) {
      parts.add('channelGroups: ${channelGroups.join(", ")}');
    }
    return 'SubscribeLoopState(${parts.join(", ")})';
  }
}
