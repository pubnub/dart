import 'package:pubnub/src/core/keyset.dart';
import 'package:pubnub/src/dx/subscribe/manager/manager.dart';
import 'package:pubnub/src/dx/subscribe/subscription.dart';

extension SubscribeKeysetExtension on Keyset {
  String get filterExpression => settings['#filterExpression'];
  set filterExpression(String value) => settings['#filterExpression'] = value;

  SubscriptionManager get subscriptionManager =>
      settings['#subscriptionManager'];
  set subscriptionManager(SubscriptionManager s) =>
      settings['#subscriptionManager'] = s;

  Set<Subscription> get subscriptions => settings['#subscriptions'];
  void addSubscription(Subscription s) {
    if (settings['#subscriptions'] is! Set<Subscription>) {
      settings['#subscriptions'] = <Subscription>{};
    }

    settings['#subscriptions'].add(s);
  }

  void removeSubscription(Subscription s) {
    if (settings['#subscriptions'] is! Set<Subscription>) {
      settings['#subscriptions'] = <Subscription>{};
    }

    settings['#subscriptions'].remove(s);
  }
}

extension PresenceKeysetExtension on Keyset {
  int get presenceTimeout => settings['#presenceTimeout'];
  set presenceTimeout(int value) => settings['#presenceTimeout'] = value;

  int get heartbeatInterval => settings['#heartbeatInterval'];
  set heartbeatInterval(int value) => settings['#heartbeatInterval'] = value;

  bool get suppressLeaveEvents => settings['#suppressLeaveEvents'];
  set suppressLeaveEvents(bool value) =>
      settings['#suppressLeaveEvents'] = value;
}
