import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';

/// Helper utilities for message action integration tests

/// Generates unique test channel names to avoid test interference
String generateTestChannel() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(99999).toString().padLeft(5, '0');
  return 'test_message_action_${timestamp}_$random';
}

/// Creates test message and returns timetoken for message action tests
Future<Timetoken> publishTestMessage(PubNub pubnub, String channel,
    [dynamic message]) async {
  message ??= {
    'test': 'message',
    'timestamp': DateTime.now().millisecondsSinceEpoch
  };
  final result = await pubnub.publish(channel, message);
  if (result.isError) {
    throw Exception('Failed to publish test message: ${result.description}');
  }
  return Timetoken(BigInt.from(result.timetoken));
}

/// Cleanup helper - removes all test actions from channel
Future<void> cleanupTestActions(PubNub pubnub, String channel) async {
  try {
    final actions = await pubnub.fetchMessageActions(channel);
    for (final action in actions.actions) {
      await pubnub.deleteMessageAction(
        channel,
        messageTimetoken: Timetoken(BigInt.parse(action.messageTimetoken)),
        actionTimetoken: Timetoken(BigInt.parse(action.actionTimetoken)),
      );
      // Small delay to avoid rate limiting
      await Future.delayed(Duration(milliseconds: 100));
    }
  } catch (e) {
    // Ignore cleanup errors - channel might be empty or actions already deleted
    print('Cleanup warning: $e');
  }
}

/// Waits for action to propagate (eventually consistent)
Future<void> waitForActionPropagation(
    [Duration delay = const Duration(seconds: 2)]) async {
  await Future.delayed(delay);
}

/// Creates a test keyset from environment variables or defaults
Keyset createTestKeyset({String? userIdSuffix}) {
  final userId = userIdSuffix != null
      ? 'integration-test-$userIdSuffix-${DateTime.now().millisecondsSinceEpoch}'
      : 'integration-test-${DateTime.now().millisecondsSinceEpoch}';

  return Keyset(
    subscribeKey: Platform.environment['SDK_SUB_KEY'] ?? 'demo',
    publishKey: Platform.environment['SDK_PUB_KEY'] ?? 'demo',
    userId: UserId(userId),
  );
}

/// Creates a PAM-enabled keyset for authentication tests
Keyset createPamKeyset({String? userIdSuffix, String? authKey}) {
  final userId = userIdSuffix != null
      ? 'pam-test-$userIdSuffix-${DateTime.now().millisecondsSinceEpoch}'
      : 'pam-test-${DateTime.now().millisecondsSinceEpoch}';

  return Keyset(
    subscribeKey: Platform.environment['SDK_PAM_SUB_KEY'] ?? 'demo-36',
    publishKey: Platform.environment['SDK_PAM_PUB_KEY'] ?? 'demo-36',
    secretKey: Platform.environment['SDK_PAM_SEC_KEY'] ?? 'demo-36',
    userId: UserId(userId),
    authKey: authKey,
  );
}

/// Helper to add a test message action and return the result
Future<AddMessageActionResult> addTestAction(
  PubNub pubnub,
  String channel,
  Timetoken messageTimetoken, {
  String type = 'reaction',
  String value = 'thumbs_up',
}) async {
  final result = await pubnub.addMessageAction(
    type: type,
    value: value,
    channel: channel,
    timetoken: messageTimetoken,
  );
  return result;
}

/// Helper to verify action exists in fetch results
bool actionExistsInResults(
    List<MessageAction> actions, String actionTimetoken) {
  return actions.any((action) => action.actionTimetoken == actionTimetoken);
}

/// Helper to get action count for specific type
int getActionCountByType(List<MessageAction> actions, String type) {
  return actions.where((action) => action.type == type).length;
}

/// Helper to verify actions are in timetoken order (ascending)
bool areActionsInTimetokenOrder(List<MessageAction> actions) {
  if (actions.length <= 1) return true;

  for (int i = 1; i < actions.length; i++) {
    final prev = BigInt.parse(actions[i - 1].actionTimetoken);
    final curr = BigInt.parse(actions[i].actionTimetoken);
    if (prev > curr) return false;
  }
  return true;
}

/// Test helper that adds multiple actions to a message
Future<List<AddMessageActionResult>> addMultipleTestActions(
  PubNub pubnub,
  String channel,
  Timetoken messageTimetoken, {
  List<String> types = const [
    'reaction',
    'receipt',
    'bookmark',
    'flag',
    'custom'
  ],
  List<String> values = const [
    'thumbs_up',
    'read',
    'saved',
    'inappropriate',
    'star'
  ],
}) async {
  final results = <AddMessageActionResult>[];

  for (int i = 0; i < types.length && i < values.length; i++) {
    final result = await addTestAction(
      pubnub,
      channel,
      messageTimetoken,
      type: types[i],
      value: values[i],
    );
    results.add(result);
    // Small delay to ensure different timetokens
    await Future.delayed(Duration(milliseconds: 200));
  }

  return results;
}

/// Helper to create multiple test channels
List<String> generateMultipleTestChannels(int count) {
  return List.generate(count, (_) => generateTestChannel());
}

/// Helper to run concurrent operations and measure timing
Future<List<T>> runConcurrentOperations<T>(
    List<Future<T> Function()> operations) async {
  final futures = operations.map((op) => op()).toList();
  return await Future.wait(futures);
}

/// Helper to verify Unicode and special character preservation
bool verifySpecialCharacters(String original, String retrieved) {
  return original == retrieved;
}

/// Custom matcher for message actions
class MessageActionMatcher extends Matcher {
  final String expectedType;
  final String expectedValue;
  final String? expectedMessageTimetoken;
  final String? expectedUuid;

  MessageActionMatcher({
    required this.expectedType,
    required this.expectedValue,
    this.expectedMessageTimetoken,
    this.expectedUuid,
  });

  @override
  Description describe(Description description) => description.add(
      'matches MessageAction with type: $expectedType, value: $expectedValue');

  @override
  bool matches(item, Map matchState) {
    if (item is! MessageAction) return false;

    if (item.type != expectedType) return false;
    if (item.value != expectedValue) return false;
    if (expectedMessageTimetoken != null &&
        item.messageTimetoken != expectedMessageTimetoken) return false;
    if (expectedUuid != null && item.uuid != expectedUuid) return false;

    return true;
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is MessageAction) {
      mismatchDescription.add(
          'got MessageAction with type: ${item.type}, value: ${item.value}');
    } else {
      mismatchDescription.add('got ${item.runtimeType}');
    }
    return mismatchDescription;
  }
}

/// Retry helper for flaky network operations
Future<T> retryOperation<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  Exception? lastException;

  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await operation();
    } catch (e) {
      lastException = e is Exception ? e : Exception(e.toString());
      if (attempt < maxRetries - 1) {
        await Future.delayed(delay);
      }
    }
  }

  throw lastException!;
}

/// Helper to check if we're in CI environment
bool get isCI => Platform.environment['CI'] != null;

/// Helper to get test timeout based on environment
Duration get testTimeout => isCI ? Duration(minutes: 5) : Duration(minutes: 2);

/// Performance threshold helpers
const Duration addActionThreshold = Duration(milliseconds: 500);
const Duration fetchActionsThreshold = Duration(milliseconds: 1000);
const Duration deleteActionThreshold = Duration(milliseconds: 300);

/// Helper to measure operation timing
Future<({T result, Duration duration})> measureOperation<T>(
    Future<T> Function() operation) async {
  final stopwatch = Stopwatch()..start();
  final result = await operation();
  stopwatch.stop();
  return (result: result, duration: stopwatch.elapsed);
}
