import 'package:pubnub/core.dart';

/// @nodoc
class SubscribeFiber implements Fiber {
  @override
  int tries;

  SubscribeFiber(this.tries);

  @override
  final action = () async => {};

  @override
  final bool isSubscribe = true;

  @override
  // TODO: implement future
  final Future future = Future.value(null);

  @override
  // TODO: implement id
  final int id = -1;

  @override
  Future<void> run() async {}
}
