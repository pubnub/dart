import 'package:flutter/widgets.dart';
import 'package:pubnub/pubnub.dart';

import 'cache.dart';

class PubNubProvider extends InheritedWidget {
  final PubNub instance;
  final Cache cache;
  @override
  final Widget child;

  PubNubProvider(
      {Key? key,
      required this.instance,
      required this.child,
      required this.cache})
      : super(key: key, child: child);

  static PubNubProvider of(BuildContext context) {
    var provider = context.dependOnInheritedWidgetOfExactType<PubNubProvider>();

    assert(provider != null);

    return provider!;
  }

  bool get cacheEnabled => cache != null;

  @override
  bool updateShouldNotify(covariant PubNubProvider oldWidget) => false;
}
