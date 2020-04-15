import 'package:pubnub/src/core/keyset.dart';
import 'package:pubnub/src/dx/subscribe/manager/manager.dart';
import 'package:pubnub/src/dx/subscribe/subscription.dart';

extension SubscribeKeysetExtension on Keyset {
  String get filterExpression => this.settings[#finalExpression];
  void set filterExpression(String value) =>
      this.settings[#finalExpression] = value;

  SubscriptionManager get subscriptionManager =>
      this.settings[#subscriptionManager];
  void set subscriptionManager(SubscriptionManager s) =>
      this.settings[#subscriptionManager] = s;

  Set<Subscription> get subscriptions => this.settings[#subscriptions];
  void addSubscription(Subscription s) {
    if (this.settings[#subscriptions] is! Set<Subscription>) {
      this.settings[#subscriptions] = Set<Subscription>();
    }

    this.settings[#subscriptions].add(s);
  }

  void removeSubscription(Subscription s) {
    if (this.settings[#subscriptions] is! Set<Subscription>) {
      this.settings[#subscriptions] = Set<Subscription>();
    }

    this.settings[#subscriptions].remove(s);
  }
}

extension PresenceKeysetExtension on Keyset {
  int get presenceTimeout => this.settings[#presenceTimeout];
  void set presenceTimeout(int value) =>
      this.settings[#presenceTimeout] = value;

  int get heartbeatInterval => this.settings[#heartbeatInterval];
  void set heartbeatInterval(int value) =>
      this.settings[#heartbeatInterval] = value;

  bool get suppressLeaveEvents => this.settings[#suppressLeaveEvents];
  void set suppressLeaveEvents(bool value) =>
      this.settings[#suppressLeaveEvents] = value;
}
