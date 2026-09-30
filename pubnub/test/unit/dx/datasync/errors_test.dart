import 'package:test/test.dart';

import 'package:pubnub/pubnub.dart';

import '_helpers.dart';

void main() {
  late PubNub pubnub;

  setUp(() {
    pubnub = newClient();
  });

  void mockFailure(int status, String responseBody) {
    when(method: 'GET', path: dsPath('entities', id: 'e'))
        .then(status: status, body: responseBody);
  }

  group('DataSync errors', () {
    test('surfaces every reported error, the first one as error', () async {
      mockFailure(
          400,
          body({
            'errors': [
              {
                'errorCode': 'SYN-0004',
                'message': 'Invalid id',
                'path': '/data/id'
              },
              {'errorCode': 'SYN-0006', 'message': 'Property does not exist'},
            ]
          }));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errors.map((e) => e.errorCode), 'codes',
                  ['SYN-0004', 'SYN-0006'])
              .having((e) => e.path, 'path', '/data/id')
              .having((e) => e.errors[1].path, 'errors[1].path', isNull)
              .having((e) => e.message, 'message',
                  contains('SYN-0004: Invalid id (at /data/id)'))));
    });

    test('the first reported error is the exception itself', () async {
      mockFailure(
          400,
          body({
            'errors': [
              {'errorCode': 'SYN-0004', 'message': 'Invalid id'},
              {'errorCode': 'SYN-0006', 'message': 'Property does not exist'},
            ]
          }));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<DataSyncException>()
              .having((e) => identical(e.errors.first, e), 'errors.first', true)
              .having(
                  (e) => e.errors[1].errors, 'errors[1].errors', hasLength(1))
              .having((e) => e.errors.map((e) => e.statusCode), 'statusCodes',
                  [400, 400])));
    });

    test('a single error lists only itself', () async {
      mockFailure(404, body(notFoundError('e')));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errors, 'errors', hasLength(1))
              .having((e) => e.errorMessage, 'errorMessage',
                  'Entity not found: e')));
    });

    test('maps an Access Manager DataSync denial to DataSyncException',
        () async {
      mockFailure(
          403,
          body({
            'errors': [
              {'errorCode': 'DS-0202', 'message': 'Invalid auth'}
            ]
          }));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode', 'DS-0202')));
    });

    test('maps an Access Manager Forbidden envelope to ForbiddenException',
        () async {
      mockFailure(403, body(accessDeniedError));

      await expectLater(
          pubnub.dataSync.getEntity('e'), throwsA(isA<ForbiddenException>()));
    });

    // Regression for B11: a missing `errorCode` used to become 'null'.
    test('reports a missing errorCode as unknown', () async {
      mockFailure(
          400,
          body({
            'errors': [
              {'message': 'no code'}
            ]
          }));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode',
                  DataSyncException.unknownErrorCode)
              .having((e) => e.errorMessage, 'errorMessage', 'no code')));
    });

    // Regression for B11: error item parsing used to assume a map.
    test('keeps an errors item that is not a map as its message', () async {
      mockFailure(
          400,
          body({
            'errors': ['plain text error']
          }));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.errorCode, 'errorCode',
                  DataSyncException.unknownErrorCode)
              .having(
                  (e) => e.errorMessage, 'errorMessage', 'plain text error')));
    });

    // Regression for B12: `Token is revoked.` without `service` used to hit
    // `result.service!`.
    test('maps a revoked token without service to ForbiddenException',
        () async {
      mockFailure(403, body({'status': 403, 'message': 'Token is revoked.'}));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<ForbiddenException>()
              .having((e) => e.service, 'service', 'Access Manager')
              .having((e) => e.reason, 'reason', 'Token is revoked.')));
    });

    // Regression for B12: the missing parentheses used to map a revoked token
    // message to ForbiddenException for any status.
    test('maps "Token is revoked." only for status 403', () async {
      mockFailure(400, body({'status': 400, 'message': 'Token is revoked.'}));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(
              allOf(isA<PubNubException>(), isNot(isA<ForbiddenException>()))));
    });

    test('exposes the HTTP status on DataSyncException', () async {
      mockFailure(404, body(notFoundError('e')));

      await expectLater(
          pubnub.dataSync.getEntity('e'),
          throwsA(isA<DataSyncException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('status 404'))));
    });

    // Regression for B13: a failure without a body used to lose its HTTP
    // status and could not be told apart from other failures.
    test('reports the HTTP status of a failure without a body', () async {
      when(
        method: 'DELETE',
        path: dsPath('entities', id: 'e'),
        headers: header('If-Match', 'stale'),
      ).then(status: 412, body: '');

      await expectLater(
          pubnub.dataSync.removeEntity('e', ifMatchesEtag: 'stale'),
          throwsA(isA<PubNubException>()
              .having((e) => e.message, 'message', contains('status 412'))));
    });

    test('maps a non JSON server error to a PubNubException', () async {
      mockFailure(502, '<html>Bad Gateway</html>');

      await expectLater(
          pubnub.dataSync.getEntity('e'), throwsA(isA<PubNubException>()));
    });
  });
}
