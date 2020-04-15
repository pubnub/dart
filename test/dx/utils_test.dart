import 'package:test/test.dart';
import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';

void main() {
  group('DX [_utils]', () {
    group('DefaultResult', () {
      test('should properly serialize an error message', () {
        var input = {
          'status': 400,
          'error': true,
          'error_message': 'Invalid Arguments',
          'channels': {}
        };

        var result = DefaultResult.fromJson(input);

        expect(result, isA<DefaultResult>());
        expect(result.isError, equals(true));
        expect(result.status, equals(400));
        expect(result.message, equals('Invalid Arguments'));
        expect(result.service, equals(null));
        expect(result.otherKeys, equals({'channels': {}}));
      });
    });
    group('computeSignature', () {
      test('computeSignature should return valid signature', () {
        var keyset =
            Keyset(subscribeKey: 'test', publishKey: 'test', authKey: 'test');
        var requestType = RequestType.post;
        var queryParams = {'test': 'test'};
        var path = ['test', 'test'];
        var payload = 'test';
        var expectedSign =
            "v2.3932952f437cb9d755ec069ec0f59869340d014233ec9ef780046beda716d0d6";

        var response = computeSignature(keyset, requestType, queryParams, path,
            payload: payload);
        expect(response, expectedSign);
      });
      test(
          'computeSignature should return valid signature for multiple query params',
          () {
        var keyset =
            Keyset(subscribeKey: 'test', publishKey: 'test', authKey: 'test');
        var requestType = RequestType.post;
        var queryParams = {'test': 'test', 'time': '1234'};
        var path = ['test', 'test'];
        var payload = 'test';
        var expectedSign =
            "v2.030378a517843a7a32c798ac5bb61851cc620458af92d00215417a469e255974";

        var response = computeSignature(keyset, requestType, queryParams, path,
            payload: payload);
        expect(response, expectedSign);
      });
    });
  });
}
