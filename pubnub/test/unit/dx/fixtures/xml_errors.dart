part of '../xml_error_handling_test.dart';

// XML Error Response Fixtures for Unit Tests
final _unitTestEntityTooLargeXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>EntityTooLarge</Code>
  <Message>Your proposed upload exceeds the maximum allowed size</Message>
  <ProposedSize>5244154</ProposedSize>
  <MaxSizeAllowed>5242880</MaxSizeAllowed>
  <RequestId>P570ENA92X4PR7DF</RequestId>
  <HostId>zYdZeAd/hIiBlNKrImKG9G3UcPZkDmlRiKr4izWWNkzkhY/cQRa6KXpbAKOOW4ut6d/HMXKEbw8=</HostId>
</Error>
''';

final _unitTestAccessDeniedXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>AccessDenied</Code>
  <Message>Access Denied</Message>
  <RequestId>ABC123DEF456</RequestId>
</Error>
''';

final _unitTestNoSuchKeyXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>NoSuchKey</Code>
  <Message>The specified key does not exist.</Message>
  <Key>files/nonexistent-file-id/nonexistent-file.txt</Key>
  <RequestId>XYZ789ABC123</RequestId>
  <HostId>example-host-id</HostId>
</Error>
''';

final _unitTestEmptyElementsXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code></Code>
  <Message></Message>
  <RequestId>EMPTY123</RequestId>
</Error>
''';

final _unitTestSpecialCharactersXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>InvalidArgument</Code>
  <Message>Invalid argument: &lt;test&gt; &amp; "quotes"</Message>
  <RequestId>SPECIAL123</RequestId>
</Error>
''';

final _unitTestNestedElementsXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>ComplexError</Code>
  <Details>
    <SubCode>NESTED_ERROR</SubCode>
    <SubMessage>This is a nested error message</SubMessage>
  </Details>
  <RequestId>NESTED123</RequestId>
</Error>
''';

final _unitTestMalformedXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>MalformedTest</Code>
  <Message>This is a test message</Message>
</Error>
''';

final _unitTestEmptyRootElementXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error></Error>
''';

final _unitTestDifferentRootElementXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<S3Error>
  <Code>InternalError</Code>
  <Message>We encountered an internal error. Please try again.</Message>
  <RequestId>INTERNAL123</RequestId>
</S3Error>
''';

final _unitTestAwsS3FileSizeExceededXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>EntityTooLarge</Code>
  <Message>Your proposed upload exceeds the maximum allowed size</Message>
  <ProposedSize>5244154</ProposedSize>
  <MaxSizeAllowed>5242880</MaxSizeAllowed>
  <RequestId>P570ENA92X4PR7DF</RequestId>
  <HostId>zYdZeAd/hIiBlNKrImKG9G3UcPZkDmlRiKr4izWWNkzkhY/cQRa6KXpbAKOOW4ut6d/HMXKEbw8=</HostId>
</Error>
''';

final _unitTestAwsS3FileNotFoundXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>NoSuchKey</Code>
  <Message>The specified key does not exist.</Message>
  <Key>files/invalid-file-id/invalid-file.txt</Key>
  <RequestId>4442587FB7D0A2F9</RequestId>
  <HostId>9+qQfpZ9cGBFuPiXJKiKk9dAqNuUKiXiCqVf9QKdGJZLjQJNvGRXVGRJD3Qx3QYb</HostId>
</Error>
''';

final _unitTestAwsS3AccessDeniedXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>AccessDenied</Code>
  <Message>Access Denied</Message>
  <RequestId>656c76696e6727732072657175657374</RequestId>
  <HostId>Uuag1LuByRx9e6j5Onimru9pO4ZVKnJ2Qz7/C1NPcfTWAtRPfTaOFg==</HostId>
</Error>
''';

final _unitTestAwsS3SignatureMismatchXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>SignatureDoesNotMatch</Code>
  <Message>The request signature we calculated does not match the signature you provided.</Message>
  <AWSAccessKeyId>AKIAIOSFODNN7EXAMPLE</AWSAccessKeyId>
  <StringToSign>AWS4-HMAC-SHA256...</StringToSign>
  <RequestId>4442587FB7D0A2F9</RequestId>
  <HostId>9+qQfpZ9cGBFuPiXJKiKk9dAqNuUKiXiCqVf9QKdGJZLjQJNvGRXVGRJD3Qx3QYb</HostId>
</Error>
''';
