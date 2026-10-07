@TestOn('vm')
@Tags(['integration'])

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

import '_helpers.dart';

const _customerSecret = 'customer-private-value';
const _settle = Duration(seconds: 3);

void _expectFields(Map<String, dynamic>? payload, List<String> fields) =>
    expect(payload!.keys.toList()..sort(), equals(fields));

void main() {
  late PubNub pubnub;
  late Cleanup cleanup;
  late String id;

  setUp(() {
    pubnub = superClient();
    cleanup = Cleanup();
    id = freshId('dartcustomer');
  });

  tearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });

  group('DataSync events [entity subscription]', () {
    test('base and admin entity subscriptions receive their own projection',
        () async {
      var base = pubnub.dataSyncEntity(id).subscription();
      var admin = pubnub.dataSyncEntity(id).subscription(projection: 'admin');
      expect(admin.channels, equals({'__admin__$id'}));
      base.subscribe();
      admin.subscribe();

      var baseEvent =
          base.dataSync.firstWhere(eventFor(DataSyncEventType.create, id));
      var adminEvent =
          admin.dataSync.firstWhere(eventFor(DataSyncEventType.create, id));
      try {
        // Both subscriptions share one loop, and `whenStarts` of a loop that
        // has already started only completes with the next one.
        await admin.whenStarts;
        await Future<void>.delayed(_settle);

        await createCustomer(pubnub, cleanup, id,
            overrides: {'private': _customerSecret});

        var fromBase = await baseEvent.timeout(eventTimeout);
        expect(fromBase.channel, equals(id));
        _expectFields(fromBase.payload, customerDefaultFields);

        var fromAdmin = await adminEvent.timeout(eventTimeout);
        expect(fromAdmin.channel, equals('__admin__$id'));
        expect(fromAdmin.id, equals(id));
        _expectFields(fromAdmin.payload, customerAdminFields);
        expect(fromAdmin.payload!['private'], equals(_customerSecret));
      } finally {
        baseEvent.ignore();
        adminEvent.ignore();
        await base.cancel();
        await admin.cancel();
      }
    });
  });
}
