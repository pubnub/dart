import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:pubnub/core.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/core/exceptions.dart' as core_exceptions;
part 'fixtures/xml_errors.dart';

void main() {
  group('XML Error Handling Tests', () {
    test('should parse EntityTooLarge XML error correctly', () {
      final xmlDocument = XmlDocument.parse(_unitTestEntityTooLargeXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Request failed. Details:'));
      expect(exception.message, contains('Code: EntityTooLarge'));
      expect(
          exception.message,
          contains(
              'Message: Your proposed upload exceeds the maximum allowed size'));
      expect(exception.message, contains('ProposedSize: 5244154'));
      expect(exception.message, contains('MaxSizeAllowed: 5242880'));
      expect(exception.message, contains('RequestId: P570ENA92X4PR7DF'));
      expect(exception.message, contains('HostId:'));
    });

    test('should parse AccessDenied XML error correctly', () {
      final xmlDocument = XmlDocument.parse(_unitTestAccessDeniedXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Code: AccessDenied'));
      expect(exception.message, contains('Message: Access Denied'));
      expect(exception.message, contains('RequestId: ABC123DEF456'));
    });

    test('should parse NoSuchKey XML error correctly', () {
      final xmlDocument = XmlDocument.parse(_unitTestNoSuchKeyXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Code: NoSuchKey'));
      expect(exception.message,
          contains('Message: The specified key does not exist.'));
      expect(exception.message,
          contains('Key: files/nonexistent-file-id/nonexistent-file.txt'));
      expect(exception.message, contains('RequestId: XYZ789ABC123'));
    });

    test('should handle XML error with empty elements', () {
      final xmlDocument = XmlDocument.parse(_unitTestEmptyElementsXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Code: '));
      expect(exception.message, contains('Message: '));
      expect(exception.message, contains('RequestId: EMPTY123'));
    });

    test('should handle XML error with special characters', () {
      final xmlDocument = XmlDocument.parse(_unitTestSpecialCharactersXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Code: InvalidArgument'));
      expect(exception.message,
          contains('Message: Invalid argument: <test> & "quotes"'));
      expect(exception.message, contains('RequestId: SPECIAL123'));
    });

    test('should handle XML error with nested elements', () {
      final xmlDocument = XmlDocument.parse(_unitTestNestedElementsXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Code: ComplexError'));
      expect(exception.message, contains('Details:'));
      expect(exception.message, contains('NESTED_ERROR'));
      expect(exception.message, contains('This is a nested error message'));
      expect(exception.message, contains('RequestId: NESTED123'));
    });

    test('should handle malformed XML gracefully', () {
      // This test checks if the function can handle cases where XML parsing might fail
      // In practice, this would likely throw during XmlDocument.parse() before reaching getExceptionFromAny
      final xmlDocument = XmlDocument.parse(_unitTestMalformedXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Code: MalformedTest'));
      expect(exception.message, contains('Message: This is a test message'));
    });

    test('should handle XML with only root element', () {
      final xmlDocument = XmlDocument.parse(_unitTestEmptyRootElementXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, equals('Request failed. Details: '));
    });

    test('should handle XML with different root element name', () {
      final xmlDocument = XmlDocument.parse(_unitTestDifferentRootElementXml);
      final exception = getExceptionFromAny(xmlDocument);

      expect(exception, isA<PubNubException>());
      expect(exception.message, contains('Code: InternalError'));
      expect(
          exception.message,
          contains(
              'Message: We encountered an internal error. Please try again.'));
      expect(exception.message, contains('RequestId: INTERNAL123'));
    });

    group('Non-XML error handling', () {
      test('should handle DefaultResult errors', () {
        // Create DefaultResult using fromJson to properly set internal fields
        final defaultResult = DefaultResult.fromJson({
          'status': 400,
          'message': 'Invalid Arguments',
        });

        final exception = getExceptionFromAny(defaultResult);

        expect(exception, isA<core_exceptions.InvalidArgumentsException>());
      });

      test('should handle List errors', () {
        final listError = [0, 'Publish failed', '15566918187234'];

        final exception = getExceptionFromAny(listError);

        expect(exception, isA<PublishException>());
        expect(exception.message, equals('Publish failed'));
      });

      test('should handle empty List errors', () {
        final emptyListError = <dynamic>[];

        final exception = getExceptionFromAny(emptyListError);

        expect(exception, isA<UnknownException>());
      });

      test('should handle unknown error types', () {
        final unknownError = 'Some string error';

        final exception = getExceptionFromAny(unknownError);

        expect(exception, isA<PubNubException>());
        expect(
            exception.message, equals('unknown exception: Some string error'));
      });
    });

    group('Real-world AWS S3 error scenarios', () {
      test('should handle file size exceeded error from AWS S3', () {
        final xmlDocument =
            XmlDocument.parse(_unitTestAwsS3FileSizeExceededXml);
        final exception = getExceptionFromAny(xmlDocument);

        expect(exception, isA<PubNubException>());
        expect(exception.message, contains('EntityTooLarge'));
        expect(exception.message, contains('exceeds the maximum allowed size'));
        expect(exception.message, contains('5244154')); // Proposed size
        expect(exception.message, contains('5242880')); // Max allowed size
      });

      test('should handle file not found error from AWS S3', () {
        final xmlDocument = XmlDocument.parse(_unitTestAwsS3FileNotFoundXml);
        final exception = getExceptionFromAny(xmlDocument);

        expect(exception, isA<PubNubException>());
        expect(exception.message, contains('NoSuchKey'));
        expect(exception.message, contains('specified key does not exist'));
        expect(exception.message,
            contains('files/invalid-file-id/invalid-file.txt'));
      });

      test('should handle access denied error from AWS S3', () {
        final xmlDocument = XmlDocument.parse(_unitTestAwsS3AccessDeniedXml);
        final exception = getExceptionFromAny(xmlDocument);

        expect(exception, isA<PubNubException>());
        expect(exception.message, contains('AccessDenied'));
        expect(exception.message, contains('Access Denied'));
      });

      test('should handle signature mismatch error from AWS S3', () {
        final xmlDocument =
            XmlDocument.parse(_unitTestAwsS3SignatureMismatchXml);
        final exception = getExceptionFromAny(xmlDocument);

        expect(exception, isA<PubNubException>());
        expect(exception.message, contains('SignatureDoesNotMatch'));
        expect(exception.message,
            contains('signature we calculated does not match'));
        expect(exception.message, contains('AKIAIOSFODNN7EXAMPLE'));
      });
    });
  });
}
