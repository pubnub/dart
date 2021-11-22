import 'package:pubnub/pubnub.dart';
import 'package:test/test.dart';
import 'package:pubnub/core.dart';
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
        PubNub.version = '1.0.0';
        Core.version = '1.0.0';
        Time.mock(DateTime.fromMillisecondsSinceEpoch(1234567890000));
        var keyset = Keyset(
            subscribeKey: 'test',
            publishKey: 'test',
            secretKey: 'test',
            uuid: UUID('test'));
        var requestType = RequestType.post;
        var queryParams = {'b': 'second', 'c': 'third', 'a': 'first'};
        var path = ['test', 'test'];
        var body = 'test';
        var expectedSign = 'v2.GtlYbLJgz5DjClB2Z2o47BbJngI7uQ3E07HUnL1NN3Q';

        var response =
            computeV2Signature(keyset, requestType, path, queryParams, body);
        expect(response, equals(expectedSign));
      });
    });
  });
}
