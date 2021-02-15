import 'package:flutter/widgets.dart';

mixin DidInitState<T extends StatefulWidget> on State<T> {
  bool _didInitState = false;

  @override
  @mustCallSuper
  void didChangeDependencies() {
    if (_didInitState == false) {
      didInitState();
      _didInitState = true;
    }

    super.didChangeDependencies();
  }

  void didInitState();
}
