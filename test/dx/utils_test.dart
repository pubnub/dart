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
    group('computeV2Signature', () {
      test('computeV2Signature should return valid signature', () {
        var keyset = Keyset(
            subscribeKey: 'test',
            publishKey: 'test',
            secretKey: 'test',
            uuid: UUID('test'));
        var requestType = RequestType.post;
        var queryParams = {'b': 'second', 'c': 'third', 'a': 'first'};
        var path = ['test', 'test'];
        var body = 'test';
        var expectedSign = 'v2.oJhS84g84BXVr3QwKIAt0w7MnlB-kCW3RF5jJgZWufM';

        var response =
            computeV2Signature(keyset, requestType, path, queryParams, body);
        expect(response, equals(expectedSign));
      });
    });
  });
}
