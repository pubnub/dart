import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pubnub/pubnub.dart';

mixin SubscriptionMemory<T extends StatefulWidget> on State<T> {
  final List<dynamic> _cancellables = [];

  S remember<S>(S subscription) {
    _cancellables.add(subscription);

    return subscription;
  }

  void bind<S>(Stream<S> stream, void Function(S) callback) {
    remember(stream.listen((value) {
      setState(() {
        callback(value);
      });
    }));
  }

  Future<void> forget() async {
    for (var cancellable in _cancellables) {
      if (cancellable is Subscription || cancellable is StreamSubscription) {
        await cancellable.cancel();
      }
    }

    _cancellables.clear();
  }
}
