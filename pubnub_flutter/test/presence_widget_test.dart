import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pubnub/pubnub.dart';

import 'package:pubnub_flutter/pubnub_flutter.dart';

import '_fake_net.dart';
import '_utils.dart';

void main() {
  PubNub pubnub;

  setUp(() {
    pubnub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'demo',
          publishKey: 'demo',
          uuid: UUID('pubnub_flutter_test'),
        ),
        networking: FakeNetworkingModule());
  });

  testWidgets('PresenceWidget', (tester) async {
    when(
      path:
          '/v2/presence/sub_key/demo/channel/,/heartbeat?uuid=pubnub_flutter_test&heartbeat=3',
      method: 'GET',
    ).then(status: 200, body: '{}');

    when(
      path:
          '/v2/presence/sub_key/demo/channel/,/heartbeat?uuid=pubnub_flutter_test&heartbeat=5',
      method: 'GET',
    ).then(status: 200, body: '{}');

    when(
      path:
          '/v2/presence/sub_key/demo/channel/,/leave?uuid=pubnub_flutter_test',
      method: 'GET',
    ).then(status: 200, body: '{}');

    when(
      path:
          '/v2/presence/sub_key/demo/channel/,/heartbeat?uuid=pubnub_flutter_test&heartbeat=10',
      method: 'GET',
    ).then(status: 200, body: '{}');

    when(
      path:
          '/v2/presence/sub_key/demo/channel/,/leave?uuid=pubnub_flutter_test',
      method: 'GET',
    ).then(status: 200, body: '{}');

    await buildWidget(
      PresenceWidget(
        child: Text('word'),
        online: true,
        heartbeatInterval: 3,
        announceLeave: true,
      ),
      tester: tester,
      pubnub: pubnub,
    );

    await tester.pump(Duration(seconds: 3));

    final textFinder = find.text('word');
    expect(textFinder, findsOneWidget);

    await buildWidget(
      PresenceWidget(
        child: Text('other'),
        online: true,
        heartbeatInterval: 5,
        announceLeave: true,
      ),
      tester: tester,
      pubnub: pubnub,
    );

    await tester.pump(Duration(seconds: 5));

    final otherFinder = find.text('other');
    expect(otherFinder, findsOneWidget);

    await buildWidget(
      PresenceWidget(
        child: Text('other'),
        online: false,
        heartbeatInterval: 7,
        announceLeave: true,
      ),
      tester: tester,
      pubnub: pubnub,
    );

    await tester.pump(Duration(seconds: 10));

    await buildWidget(
      PresenceWidget(
        child: Text('other'),
        online: true,
        heartbeatInterval: 10,
        announceLeave: true,
      ),
      tester: tester,
      pubnub: pubnub,
    );

    await tester.pump(Duration(seconds: 15));

    await buildWidget(Text('done'), tester: tester, pubnub: pubnub);

    await tester.pump(Duration(seconds: 15));
  });
}
