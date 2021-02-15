import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub_flutter/pubnub_flutter.dart';

class App extends StatelessWidget {
  final Widget child;

  final PubNub pubnub;

  App({this.child, this.pubnub});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: Color.fromRGBO(255, 0, 0, 1),
      builder: (context, _) => PubNubProvider(
        instance: pubnub,
        child: child,
      ),
    );
  }
}

Future<Widget> buildWidget(Widget widget,
    {WidgetTester tester, PubNub pubnub}) async {
  await tester.pumpWidget(App(child: widget, pubnub: pubnub));

  return widget;
}
