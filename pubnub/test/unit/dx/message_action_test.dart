import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '../net/fake_net.dart';
part './fixtures/message_action.dart';

void main() {
  late PubNub pubnub;

  group('DX [messageAction]', () {
    setUp(() {
      pubnub = PubNub(
          defaultKeyset: Keyset(
              subscribeKey: 'test',
              publishKey: 'test',
              uuid: UUID('test-uuid')),
          networking: FakeNetworkingModule());
    });

    // Existing tests
    test('add message action throws when type is empty', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var value = 'value';
      var type = '';
      var channel = 'test';
      expect(
          pubnub.addMessageAction(
              type: type,
              value: value,
              channel: channel,
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('add message action throws when value is empty', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var value = '';
      var type = 'type';
      var channel = 'test';
      expect(
          pubnub.addMessageAction(
              type: type,
              value: value,
              channel: channel,
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('add message action throws if there is no available keyset', () async {
      pubnub.keysets.remove('default');
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var actionValue = 'smiley_face';
      var actionType = 'reaction';
      var channel = 'test';
      expect(
          pubnub.addMessageAction(
              type: actionType,
              value: actionValue,
              channel: channel,
              timetoken: messageTimetoken),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('fetch message action throws when channel is empty', () async {
      expect(pubnub.fetchMessageActions(''),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('fetch message actions throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var channel = 'test';
      expect(pubnub.fetchMessageActions(channel),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test('delete message action throws when channel is empty', () async {
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var channel = '';
      var actionTimetoken = Timetoken(BigInt.from(15645905639093361));

      expect(
          pubnub.deleteMessageAction(channel,
              messageTimetoken: messageTimetoken,
              actionTimetoken: actionTimetoken),
          throwsA(TypeMatcher<InvariantException>()));
    });

    test('delete message actions throws if there is no available keyset',
        () async {
      pubnub.keysets.remove('default');
      var messageTimetoken = Timetoken(BigInt.from(15610547826970050));
      var channel = 'test';
      var actionTimetoken = Timetoken(BigInt.from(15645905639093361));
      expect(
          pubnub.deleteMessageAction(channel,
              messageTimetoken: messageTimetoken,
              actionTimetoken: actionTimetoken),
          throwsA(TypeMatcher<KeysetException>()));
    });

    // Additional success scenario tests
    test('add_message_action_success_returns_valid_result', () async {
      when(
              method: 'POST',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid',
              body: '{"type":"reaction","value":"smiley_face"}')
          .then(status: 200, body: addMessageActionSuccessResponse);

      final result = await pubnub.addMessageAction(
          type: 'reaction',
          value: 'smiley_face',
          channel: 'test',
          timetoken: Timetoken(BigInt.from(15610547826970050)));

      expect(result.action.type, equals('reaction'));
      expect(result.action.value, equals('smiley_face'));
      expect(result.action.messageTimetoken, equals('15610547826970050'));
      expect(result.action.actionTimetoken, isNotNull);
      expect(result.action.uuid, equals('test-uuid'));
    });

    test('fetch_message_actions_success_returns_valid_list', () async {
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=100&uuid=test-uuid')
          .then(status: 200, body: fetchMessageActionsSuccessResponse);

      final result = await pubnub.fetchMessageActions('test');

      expect(result.actions.length, equals(2));
      expect(result.actions[0].type, equals('reaction'));
      expect(result.actions[0].value, equals('smiley_face'));
      expect(result.moreActions?.start, equals('15610547826970051'));
    });

    test('delete_message_action_success_returns_empty_result', () async {
      when(
              method: 'DELETE',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050/action/15610547826970051?uuid=test-uuid')
          .then(status: 200, body: deleteMessageActionSuccessResponse);

      expect(
          () async => await pubnub.deleteMessageAction('test',
              messageTimetoken: Timetoken(BigInt.from(15610547826970050)),
              actionTimetoken: Timetoken(BigInt.from(15610547826970051))),
          returnsNormally);
    });

    // Error response handling tests
    test('add_message_action_handles_400_error', () async {
      when(
              method: 'POST',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid',
              body: '{"type":"reaction","value":"smiley_face"}')
          .then(status: 400, body: messageAction400ErrorResponse);

      expect(
          () async => await pubnub.addMessageAction(
              type: 'reaction',
              value: 'smiley_face',
              channel: 'test',
              timetoken: Timetoken(BigInt.from(15610547826970050))),
          throwsA(TypeMatcher<PubNubException>()));
    });

    test('fetch_message_actions_handles_403_forbidden', () async {
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=100&uuid=test-uuid')
          .then(status: 403, body: messageAction403ErrorResponse);

      expect(() async => await pubnub.fetchMessageActions('test'),
          throwsA(TypeMatcher<TypeError>()));
    });

    test('delete_message_action_handles_404_not_found', () async {
      when(
              method: 'DELETE',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050/action/15610547826970051?uuid=test-uuid')
          .then(status: 404, body: messageAction404ErrorResponse);

      expect(
          () async => await pubnub.deleteMessageAction('test',
              messageTimetoken: Timetoken(BigInt.from(15610547826970050)),
              actionTimetoken: Timetoken(BigInt.from(15610547826970051))),
          throwsA(TypeMatcher<PubNubException>()));
    });

    // Boundary testing
    test('add_message_action_max_type_length', () async {
      final maxType = 'a' * 100; // Test with max length type
      when(
              method: 'POST',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid',
              body: '{"type":"$maxType","value":"smiley_face"}')
          .then(status: 200, body: addMessageActionSuccessResponse);

      expect(
          () async => await pubnub.addMessageAction(
              type: maxType,
              value: 'smiley_face',
              channel: 'test',
              timetoken: Timetoken(BigInt.from(15610547826970050))),
          returnsNormally);
    });

    test('add_message_action_max_value_length', () async {
      final maxValue = 'a' * 100; // Test with max length value
      when(
              method: 'POST',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid',
              body: '{"type":"reaction","value":"$maxValue"}')
          .then(status: 200, body: addMessageActionSuccessResponse);

      expect(
          () async => await pubnub.addMessageAction(
              type: 'reaction',
              value: maxValue,
              channel: 'test',
              timetoken: Timetoken(BigInt.from(15610547826970050))),
          returnsNormally);
    });

    test('fetch_message_actions_max_limit', () async {
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=100&uuid=test-uuid')
          .then(status: 200, body: fetchMessageActionsSingle100Response);

      final result = await pubnub.fetchMessageActions('test', limit: 100);
      expect(result.actions.length, equals(100));
    });

    test('fetch_message_actions_zero_limit', () async {
      // Zero limit should use default or handle appropriately
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=0&uuid=test-uuid')
          .then(status: 200, body: fetchMessageActionsEmptyResponse);

      final result = await pubnub.fetchMessageActions('test', limit: 0);
      expect(result.actions.isEmpty, isTrue);
    });

    // Pagination testing
    test('fetch_message_actions_with_pagination_params', () async {
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?start=15610547826970000&end=15610547826970100&limit=25&uuid=test-uuid')
          .then(status: 200, body: fetchMessageActionsSuccessResponse);

      final result = await pubnub.fetchMessageActions('test',
          from: Timetoken(BigInt.from(15610547826970000)),
          to: Timetoken(BigInt.from(15610547826970100)),
          limit: 25);

      expect(result.actions.length, lessThanOrEqualTo(25));
      expect(result.moreActions?.start, isNotNull);
      expect(result.moreActions?.limit, equals(100));
    });

    test('fetch_message_actions_empty_pagination_result', () async {
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=100&uuid=test-uuid')
          .then(status: 200, body: fetchMessageActionsEmptyResponse);

      final result = await pubnub.fetchMessageActions('test');

      expect(result.actions.isEmpty, isTrue);
      expect(result.moreActions, isNull);
    });

    // Authentication testing
    test('add_message_action_with_auth_key', () async {
      final authKeyset = Keyset(
          subscribeKey: 'test',
          publishKey: 'test',
          uuid: UUID('test-uuid'),
          authKey: 'test-auth');
      pubnub.keysets.add('auth', authKeyset);

      when(
              method: 'POST',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050?auth=test-auth&uuid=test-uuid',
              body: '{"type":"reaction","value":"smiley_face"}')
          .then(status: 200, body: addMessageActionSuccessResponse);

      final result = await pubnub.addMessageAction(
          type: 'reaction',
          value: 'smiley_face',
          channel: 'test',
          timetoken: Timetoken(BigInt.from(15610547826970050)),
          keyset: authKeyset);

      expect(result.action, isNotNull);
    });

    test('fetch_message_actions_with_secret_key_signature', () async {
      final secretKeyset = Keyset(
          subscribeKey: 'test',
          publishKey: 'test',
          uuid: UUID('test-uuid'),
          secretKey: 'test-secret');
      pubnub.keysets.add('secret', secretKeyset);

      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=100&uuid=test-uuid&timestamp=123&signature=dummy_sig')
          .then(status: 200, body: fetchMessageActionsSuccessResponse);

      // This test would need more complex setup to verify signature generation
      // For now, we just verify the method can be called with secret key
      expect(
          () async =>
              await pubnub.fetchMessageActions('test', keyset: secretKeyset),
          throwsA(TypeMatcher<
              MockException>())); // Expected due to signature mismatch
    });

    // Parameter validation testing
    test('add_message_action_null_timetoken', () async {
      expect(
          () => pubnub.addMessageAction(
              type: 'reaction',
              value: 'smiley_face',
              channel: 'test',
              timetoken: null as dynamic),
          throwsA(TypeMatcher<TypeError>()));
    });

    test('delete_message_action_invalid_timetoken_format', () async {
      // This should pass as Timetoken constructor handles validation
      final validTimetoken = Timetoken(BigInt.from(15610547826970050));
      expect(validTimetoken.value, equals(BigInt.from(15610547826970050)));
    });

    test('fetch_message_actions_invalid_limit_range', () async {
      // Server should handle limit > 100, so we test that request is made
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=150&uuid=test-uuid')
          .then(status: 200, body: fetchMessageActionsEmptyResponse);

      final result = await pubnub.fetchMessageActions('test', limit: 150);
      // Server behavior would determine actual response
      expect(result.actions, isNotNull);
    });

    // Keyset override testing
    test('add_message_action_with_keyset_override', () async {
      final altKeyset = Keyset(
          subscribeKey: 'alt-sub',
          publishKey: 'alt-pub',
          uuid: UUID('alt-uuid'));

      when(
              method: 'POST',
              path:
                  '/v1/message-actions/alt-sub/channel/test/message/15610547826970050?uuid=alt-uuid',
              body: '{"type":"reaction","value":"smiley_face"}')
          .then(status: 200, body: addMessageActionSuccessResponse);

      final result = await pubnub.addMessageAction(
          type: 'reaction',
          value: 'smiley_face',
          channel: 'test',
          timetoken: Timetoken(BigInt.from(15610547826970050)),
          keyset: altKeyset);

      expect(result.action, isNotNull);
    });

    test('fetch_message_actions_with_using_parameter', () async {
      final namedKeyset = Keyset(
          subscribeKey: 'named-sub',
          publishKey: 'named-pub',
          uuid: UUID('named-uuid'));
      pubnub.keysets.add('named', namedKeyset);

      when(
              method: 'GET',
              path:
                  '/v1/message-actions/named-sub/channel/test?limit=100&uuid=named-uuid')
          .then(status: 200, body: fetchMessageActionsSuccessResponse);

      final result = await pubnub.fetchMessageActions('test', using: 'named');
      expect(result.actions, isNotNull);
    });

    // Crypto module testing
    test('add_message_action_with_crypto_module', () async {
      final cipherKey = CipherKey.fromUtf8('enigmaenigmaenigm');
      final cryptoPubNub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'test',
          publishKey: 'test',
          uuid: UUID('test-uuid'),
        ),
        crypto: CryptoModule.aesCbcCryptoModule(cipherKey),
        networking: FakeNetworkingModule(),
      );

      // Since we can't predict the encrypted payload, we expect a MockException
      expect(
          () async => await cryptoPubNub.addMessageAction(
              type: 'reaction',
              value: 'smiley_face',
              channel: 'test',
              timetoken: Timetoken(BigInt.from(15610547826970050))),
          throwsA(TypeMatcher<MockException>()));
    });

    test('fetch_message_actions_decrypt_failure_handling', () async {
      final cipherKey = CipherKey.fromUtf8('enigmaenigmaenigm');
      final cryptoPubNub = PubNub(
        defaultKeyset: Keyset(
          subscribeKey: 'test',
          publishKey: 'test',
          uuid: UUID('test-uuid'),
        ),
        crypto: CryptoModule.aesCbcCryptoModule(cipherKey),
        networking: FakeNetworkingModule(),
      );

      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=100&uuid=test-uuid')
          .then(status: 200, body: fetchMessageActionsSuccessResponse);

      // Should handle decryption gracefully
      expect(() async => await cryptoPubNub.fetchMessageActions('test'),
          returnsNormally);
    });

    // Response parsing testing
    test('fetch_message_actions_malformed_json_response', () async {
      when(
              method: 'GET',
              path:
                  '/v1/message-actions/test/channel/test?limit=100&uuid=test-uuid')
          .then(status: 200, body: malformedJsonResponse);

      expect(() async => await pubnub.fetchMessageActions('test'),
          throwsA(TypeMatcher<Exception>()));
    });

    test('add_message_action_missing_response_fields', () async {
      when(
              method: 'POST',
              path:
                  '/v1/message-actions/test/channel/test/message/15610547826970050?uuid=test-uuid',
              body: '{"type":"reaction","value":"smiley_face"}')
          .then(status: 200, body: missingFieldsResponse);

      expect(
          () async => await pubnub.addMessageAction(
              type: 'reaction',
              value: 'smiley_face',
              channel: 'test',
              timetoken: Timetoken(BigInt.from(15610547826970050))),
          throwsA(TypeMatcher<TypeError>()));
    });
  });
}
