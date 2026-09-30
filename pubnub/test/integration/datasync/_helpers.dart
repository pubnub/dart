import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

// DataSync enabled keyset. It provisions the `DartCustomer` and
// `DartLoanQuote` entity classes, the `DartREQUESTED_BY` relationship class
// and the global User, Channel and Membership classes.
final publishKey = Platform.environment['DS_PUBLISH_KEY'];
final subscribeKey = Platform.environment['DS_SUBSCRIBE_KEY']??'';
final secretKey = Platform.environment['DS_SECRET_KEY'];

const classVersion = 1;
const customerClass = 'DartCustomer';
const loanQuoteClass = 'DartLoanQuote';
const requestedByClass = 'DartREQUESTED_BY';
const membershipClass = 'Membership';

const linkedAt = '2026-07-06T10:00:00.000Z';
const eventTimeout = Duration(seconds: 20);

final _random = Random();

/// Random number wide enough to keep the ids of test files that run
/// concurrently against the same keyset apart.
int _randomSuffix() => 100000 + _random.nextInt(900000);

/// Identifier made of [prefix] and a 6 digit random number. The service
/// rejects `_` in ids (DS-0004), so prefixes must not contain it.
String freshId(String prefix) => '$prefix-${_randomSuffix()}';

/// Single token value used to find the objects created by one test.
String runMarker() => 'm${_randomSuffix()}';

PubNub superClient({String userId = 'dsdart'}) => PubNub(
    defaultKeyset: Keyset(
        subscribeKey: subscribeKey,
        publishKey: publishKey,
        secretKey: secretKey,
        userId: UserId(userId)));

/// Super client and cleanup owned by the calling test. Both are released
/// when the test ends.
(PubNub, Cleanup) testClient() {
  var pubnub = superClient(userId: freshId('dsdart'));
  var cleanup = Cleanup();
  addTearDown(() async {
    await cleanup.run();
    await pubnub.unsubscribeAll();
  });
  return (pubnub, cleanup);
}

PubNub readerClient(String userId, String token) {
  var pubnub = PubNub(
      defaultKeyset: Keyset(
          subscribeKey: subscribeKey,
          publishKey: publishKey,
          userId: UserId(userId)));
  pubnub.setToken(token);
  return pubnub;
}

Map<String, dynamic> customerPayload(String id,
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'customerId': id,
      'firstName': 'Alice',
      'lastName': 'Verma',
      'email': 'alice.verma@acme.test',
      'creditScore': 720,
      'city': 'Pune',
      ...overrides,
    };

Map<String, dynamic> loanQuotePayload(String id,
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'quoteId': id,
      'make': 'Toyota',
      'model': 'Corolla',
      'price': 25000,
      ...overrides,
    };

Map<String, dynamic> userPayload([Map<String, dynamic> overrides = const {}]) =>
    {
      'firstName': 'Alice',
      'lastName': 'Verma',
      'email': 'alice.verma@acme.test',
      ...overrides,
    };

Map<String, dynamic> channelPayload(
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'name': 'engineering',
      'description': 'engineering',
      'kind': 'public',
      ...overrides,
    };

Map<String, dynamic> membershipPayload(
        [Map<String, dynamic> overrides = const {}]) =>
    {'role': 'member', 'joinedAt': linkedAt, ...overrides};

/// Removals of the objects created by a test, run in reverse order. Failures
/// are ignored, the object may already be removed by the test.
class Cleanup {
  final List<Future<void> Function()> _removals = [];

  void add(Future<void> Function() removal) => _removals.add(removal);

  Future<void> run() async {
    for (var removal in _removals.reversed) {
      try {
        await removal();
      } catch (_) {}
    }
    _removals.clear();
  }
}

Future<EntityRecord> createCustomer(PubNub pubnub, Cleanup cleanup, String id,
    {String className = customerClass,
    Map<String, dynamic> overrides = const {}}) async {
  var result = await pubnub.dataSync.createEntity(EntityInput(
      id: id,
      className: className,
      classVersion: classVersion,
      status: 'active',
      payload: customerPayload(id, overrides)));
  cleanup.add(() => pubnub.dataSync.removeEntity(id));
  return result.entity;
}

Future<EntityRecord> createLoanQuote(PubNub pubnub, Cleanup cleanup, String id,
    {String className = loanQuoteClass}) async {
  var result = await pubnub.dataSync.createEntity(EntityInput(
      id: id,
      className: className,
      classVersion: classVersion,
      status: 'active',
      payload: loanQuotePayload(id)));
  cleanup.add(() => pubnub.dataSync.removeEntity(id));
  return result.entity;
}

/// Creates the two endpoints of a `DartREQUESTED_BY` relationship and returns
/// their ids.
Future<(String, String)> seedRelationshipEndpoints(
    PubNub pubnub, Cleanup cleanup) async {
  var a = freshId('dartcustomer');
  var b = freshId('dartloanquote');
  await createCustomer(pubnub, cleanup, a);
  await createLoanQuote(pubnub, cleanup, b);
  return (a, b);
}

Future<RelationshipRecord> createRequestedBy(
    PubNub pubnub, Cleanup cleanup, String id, String a, String b) async {
  var result = await pubnub.dataSync.createRelationship(RelationshipInput(
      id: id,
      entityAId: a,
      entityBId: b,
      className: requestedByClass,
      classVersion: classVersion,
      status: 'active',
      payload: {'linkedAt': linkedAt}));
  cleanup.add(() => pubnub.dataSync.removeRelationship(id));
  return result.relationship;
}

Future<UserRecord> createUser(PubNub pubnub, Cleanup cleanup, String id,
    [Map<String, dynamic> overrides = const {}]) async {
  var result = await pubnub.dataSync.createUser(UserInput(
      id: id,
      classVersion: classVersion,
      status: 'active',
      payload: userPayload(overrides)));
  cleanup.add(() => pubnub.dataSync.removeUser(id));
  return result.user;
}

Future<ChannelRecord> createChannel(PubNub pubnub, Cleanup cleanup, String id,
    [Map<String, dynamic> overrides = const {}]) async {
  var result = await pubnub.dataSync.createChannel(ChannelInput(
      id: id,
      classVersion: classVersion,
      status: 'active',
      payload: channelPayload(overrides)));
  cleanup.add(() => pubnub.dataSync.removeChannel(id));
  return result.channel;
}

Future<MembershipRecord> createMembership(
    PubNub pubnub, Cleanup cleanup, String id, String userId, String channelId,
    [Map<String, dynamic> overrides = const {}]) async {
  var result = await pubnub.dataSync.createMembership(MembershipInput(
      id: id,
      userId: userId,
      channelId: channelId,
      classVersion: classVersion,
      status: 'active',
      payload: membershipPayload(overrides)));
  cleanup.add(() => pubnub.dataSync.removeMembership(id));
  return result.membership;
}

/// Subscribes to [channels], runs [trigger] once the long poll is established
/// and returns the first DataSync event that satisfies [predicate] within
/// [timeout] of the trigger completing.
Future<DataSyncEvent> captureEvent(PubNub pubnub, Set<String> channels,
    bool Function(DataSyncEvent) predicate, Future<void> Function() trigger,
    {Duration settle = const Duration(seconds: 3),
    Duration timeout = eventTimeout}) async {
  var subscription = pubnub.subscribe(channels: channels);
  var event = subscription.dataSync.firstWhere(predicate);
  try {
    await subscription.whenStarts;
    // Events are only delivered once the long poll is established.
    await Future<void>.delayed(settle);
    await trigger();
    return await event.timeout(timeout);
  } finally {
    event.ignore();
    await subscription.cancel();
  }
}

/// Next event of [queue] that satisfies [predicate], skipping the others.
Future<DataSyncEvent> nextEvent(
    StreamQueue<DataSyncEvent> queue, bool Function(DataSyncEvent) predicate,
    {Duration timeout = eventTimeout}) async {
  Future<DataSyncEvent> take() async {
    while (true) {
      var event = await queue.next;
      if (predicate(event)) return event;
    }
  }

  return take().timeout(timeout);
}

/// Subscribes to [channels], runs [trigger] and expects no DataSync event
/// within [window].
Future<void> expectNoEvent(
    PubNub pubnub, Set<String> channels, Future<void> Function() trigger,
    {Duration settle = const Duration(seconds: 3),
    Duration window = const Duration(seconds: 8)}) async {
  var subscription = pubnub.subscribe(channels: channels);
  var events = <DataSyncEvent>[];
  var listener = subscription.dataSync.listen(events.add);
  try {
    await subscription.whenStarts;
    await Future<void>.delayed(settle);
    await trigger();
    await Future<void>.delayed(window);
    expect(events.map((e) => '${e.channel} ${e.event} ${e.id}'), isEmpty);
  } finally {
    await listener.cancel();
    await subscription.cancel();
  }
}

bool Function(DataSyncEvent) eventFor(DataSyncEventType type, String id,
        {String? channel}) =>
    (event) =>
        event.event == type &&
        event.id == id &&
        (channel == null || event.channel == channel);

void expectNoDuplicatedClassFields(Map<String, dynamic> data) {
  for (var key in [
    'entityClass',
    'entityClassVersion',
    'relationshipClass',
    'relationshipClassVersion'
  ]) {
    expect(data.containsKey(key), isFalse, reason: '$key must not be in data');
  }
}

void expectEventCommon(DataSyncEvent event,
    {required DataSyncEventType type,
    required DataSyncObjectType objectType,
    required String id,
    required Set<String> channelOneOf,
    String? className,
    String? classLevel}) {
  expect(event.source, equals('data-sync'));
  expect(event.version, equals('1.0'));
  expect(event.event, equals(type));
  expect(event.objectType, equals(objectType));
  expect(event.id, equals(id));
  expect(channelOneOf, contains(event.channel));
  expect(event.timetoken.value, greaterThan(BigInt.zero));
  if (className != null) expect(event.className, equals(className));
  if (classLevel != null) expect(event.classLevel, equals(classLevel));
  expect(event.classVersion, equals(classVersion));
  expectNoDuplicatedClassFields(event.data);
}

void expectPayloadContains(
    Map<String, dynamic>? actual, Map<String, dynamic> expected) {
  expect(actual, isNotNull);
  expected.forEach((key, value) {
    expect(actual![key], equals(value), reason: 'payload.$key');
  });
}

void expectEventObjectData(DataSyncEvent event,
    {String? status, Map<String, dynamic> payload = const {}}) {
  expect(event.createdAt, isA<String>());
  expect(event.updatedAt, isA<String>());
  expect(event.eTag, isA<String>());
  if (status != null) expect(event.status, equals(status));
  expectPayloadContains(event.payload, payload);
}

void expectEventDeleteData(DataSyncEvent event, String id) {
  expect(event.id, equals(id));
  for (var key in [
    'payload',
    'status',
    'entityAId',
    'entityBId',
    'channelId',
    'userId',
    'eTag'
  ]) {
    expect(event.data.containsKey(key), isFalse, reason: '$key on delete');
  }
  if (event.deletedAt != null) {
    expect(DateTime.tryParse(event.deletedAt!), isNotNull);
  }
}

/// Matcher of a [DataSyncException] reporting [errorCode].
Matcher throwsDataSync(String errorCode) => throwsA(isA<DataSyncException>()
    .having((e) => e.errorCode, 'errorCode', errorCode));
