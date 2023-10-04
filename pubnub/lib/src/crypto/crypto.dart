import 'package:pubnub/core.dart';
import 'package:pubnub/src/crypto/aesCbcCryptor.dart';
import 'package:pubnub/src/crypto/legacyCryptor.dart';
import 'cryptoConfiguration.dart';
import 'cryptorHeader.dart';

/// CryptoModule is responsible for encryption and decryption
/// of PubNub messages.
class CryptoModule implements ICryptoModule {
  final ICryptor defaultCryptor;
  List<ICryptor>? cryptors;

  late CryptoConfiguration defaultConfiguration;
  late LegacyCryptoModule legacyCryptoModule;

  CryptoModule(
      {required this.defaultCryptor,
      this.cryptors,
      this.defaultConfiguration = const CryptoConfiguration()}) {
    legacyCryptoModule =
        LegacyCryptoModule(defaultConfiguration: defaultConfiguration);
  }

  factory CryptoModule.legacyCryptoModule(CipherKey cipherKey,
      {defaultCryptoConfiguration = const CryptoConfiguration()}) {
    return CryptoModule(
        defaultCryptor: LegacyCryptor(cipherKey,
            cryptoConfiguration: defaultCryptoConfiguration),
        cryptors: <ICryptor>[AesCbcCryptor(cipherKey)]);
  }

  factory CryptoModule.aesCbcCryptoModule(CipherKey cipherKey,
      {defaultCryptoConfiguration = const CryptoConfiguration()}) {
    return CryptoModule(
        defaultCryptor: AesCbcCryptor(cipherKey),
        cryptors: <ICryptor>[
          LegacyCryptor(cipherKey,
              cryptoConfiguration: defaultCryptoConfiguration),
        ]);
  }

  @override
  List<int> encrypt(List<int> data) {
    _emptyContentValidation(data);
    var encrypted = defaultCryptor.encrypt(data);
    if (encrypted.metadata.isEmpty) return encrypted.data;

    var header =
        CryptorHeader.from(defaultCryptor.identifier, encrypted.metadata);
    var headerData = List<int>.filled(header!.length, 0);
    var pos = 0;
    headerData.setAll(pos, header.data);
    pos = header.length - encrypted.metadata.length;
    headerData.setAll(pos, encrypted.metadata);
    return [...headerData, ...encrypted.data];
  }

  @override
  List<int> decrypt(List<int> data) {
    var header = CryptorHeader.tryParse(data);
    var cryptor = _getCryptor(header);
    var headerLength = header != null ? header.length : 0;
    var metadata = headerLength > 0
        ? data.sublist((headerLength - header!.metadataLength), headerLength)
        : List<int>.empty();
    return cryptor!
        .decrypt(EncryptedData.from(data.sublist(headerLength), metadata));
  }

  ICryptor? _getCryptor(CryptorHeaderV1? header) {
    try {
      return _getAllCryptors().firstWhere(
        (element) => element.identifier == (header?.identifier ?? ''),
      );
    } catch (e) {
      throw CryptoException(
          'unknown cryptor error: none of the registered cryptor can decrypt.');
    }
  }

  List<ICryptor> _getAllCryptors() {
    return [defaultCryptor, ...cryptors ?? []];
  }

  void _emptyContentValidation(List<int> content) {
    if (content.isEmpty) {
      throw CryptoException('encryption error: empty content');
    }
  }

  @override
  List<int> decryptFileData(CipherKey key, List<int> input) {
    return legacyCryptoModule.decryptFileData(key, input);
  }

  @override
  List<int> decryptWithKey(CipherKey key, List<int> input) {
    return legacyCryptoModule.decryptWithKey(key, input);
  }

  @override
  List<int> encryptFileData(CipherKey key, List<int> input) {
    _emptyContentValidation(input);
    return legacyCryptoModule.encryptFileData(key, input);
  }

  @override
  List<int> encryptWithKey(CipherKey key, List<int> input) {
    _emptyContentValidation(input);
    return legacyCryptoModule.encryptWithKey(key, input);
  }

  /// @nodoc
  @override
  void register(Core core) {}
}
