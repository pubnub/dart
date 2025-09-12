import 'dart:convert';
import 'package:pubnub/pubnub.dart';
import 'package:pubnub/core.dart';

/// Mock crypto module that produces predictable, constant encrypted strings
/// This allows for exact URL path matching in tests
class MockCryptoModule implements ICryptoModule {
  final String _constantEncryptedMessage;
  final List<int> _constantEncryptedFileData;

  MockCryptoModule({
    String constantEncryptedMessage = 'MOCK_ENCRYPTED_MESSAGE',
    List<int>? constantEncryptedFileData,
  })  : _constantEncryptedMessage = constantEncryptedMessage,
        _constantEncryptedFileData = constantEncryptedFileData ??
            utf8.encode('MOCK_ENCRYPTED_FILE_DATA');

  @override
  void register(Core core) {
    // No registration needed for mock
  }

  @override
  List<int> encrypt(List<int> input) {
    return utf8.encode(_constantEncryptedMessage);
  }

  @override
  List<int> decrypt(List<int> input) {
    return utf8.encode('MOCK_DECRYPTED_MESSAGE');
  }

  @override
  List<int> encryptFileData(CipherKey key, List<int> input) {
    return _constantEncryptedFileData;
  }

  @override
  List<int> decryptFileData(CipherKey key, List<int> input) {
    return utf8.encode('MOCK_DECRYPTED_FILE_DATA');
  }

  @override
  List<int> encryptWithKey(CipherKey key, List<int> input) {
    return utf8.encode(_constantEncryptedMessage);
  }

  @override
  List<int> decryptWithKey(CipherKey key, List<int> input) {
    return utf8.encode('MOCK_DECRYPTED_MESSAGE');
  }
}

/// Factory to create PubNub instances with mock crypto for testing
class MockCryptoPubNub {
  static PubNub createWithMockCrypto({
    required Keyset keyset,
    required INetworkingModule networking,
    String constantEncryptedMessage = 'MOCK_ENCRYPTED_MESSAGE',
    List<int>? constantEncryptedFileData,
  }) {
    final mockCrypto = MockCryptoModule(
      constantEncryptedMessage: constantEncryptedMessage,
      constantEncryptedFileData: constantEncryptedFileData,
    );

    return PubNub(
      defaultKeyset: keyset,
      networking: networking,
      crypto: mockCrypto,
    );
  }
}
